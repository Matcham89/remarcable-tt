# Ingress is scoped to the VPC CIDR - tighten to specific task SG IDs post-MVP.
resource "aws_security_group" "aurora" {
  name        = "${var.project}-${var.environment}-aurora-postgres-sg"
  description = "Allow PostgreSQL access from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "10.2.0"

  name           = "${var.project}-${var.environment}-aurora-postgres"
  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  cluster_instance_class = var.instance_class

  # One writer for the demo. Add readers later with var.reader_count when read
  # traffic or failover requirements justify the extra monthly cost.
  instances = { for i in range(var.reader_count + 1) : tostring(i + 1) => {} }

  vpc_id  = var.vpc_id
  subnets = var.private_subnet_ids

  create_db_subnet_group = true

  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.aurora.id]

  storage_encrypted   = true
  deletion_protection = var.deletion_protection
  skip_final_snapshot = true

  # master_password_wo is write-only: applied but not stored in Terraform state.
  manage_master_user_password = false
  master_username             = "app"
  master_password_wo          = var.db_password
  master_password_wo_version  = 1

  enabled_cloudwatch_logs_exports = ["postgresql"]

  apply_immediately = false
}

# The secret is created here and seeded from var.db_password on first apply. For
# production, replace this with AWS-managed rotation that updates both Aurora and
# the secret. Updating only this secret does not rotate the database password.
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project}/${var.environment}/db"
  description             = "Aurora PostgreSQL master credentials for ${var.project} ${var.environment}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "app"
    password = var.db_password
    engine   = "aurora-postgresql"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# RDS Proxy smooths connection bursts from short-lived Fargate tasks.
# Note: If this cluster were Aurora serverless, the proxy would prevent
# scale-to-zero because it maintains persistent backend connections. For
# provisioned Aurora (which is always running), this is not a concern - we get
# only the connection pooling benefit.

resource "aws_iam_role" "rds_proxy" {
  name = "${var.project}-${var.environment}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "read-db-secret"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db.arn
      }
    ]
  })
}

resource "aws_db_proxy" "this" {
  name                   = "${var.project}-${var.environment}-rds-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.aurora.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db.arn
    description = "Aurora master credentials"
  }

  depends_on = [
    module.aurora,
    aws_iam_role_policy.rds_proxy_secrets,
    aws_secretsmanager_secret_version.db
  ]
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "this" {
  db_cluster_identifier = module.aurora.cluster_id
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "aurora_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-aurora-postgres-cpu-high"
  alarm_description   = "Aurora writer CPU above 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    DBClusterIdentifier = module.aurora.cluster_id
    Role                = "WRITER"
  }
}
