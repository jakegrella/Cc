terraform {
  cloud {
    organization = "westtt"
    workspaces {
      name = "test-workspace"
    }  
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }

    neon = {
      source  = "kislerdm/neon"
      version = "0.6.3"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
  region = "us-east-2"
}

provider "aws" {
  region = local.region
}

provider "neon" {}

# storage bucket for assets
resource "aws_s3_bucket" "this" {
  bucket_prefix = var.bucket_prefix
}

# database 
resource "neon_project" "this" {
  name                      = var.neon_project_name
  history_retention_seconds = 86400
}

resource "neon_branch" "this" {
  project_id = neon_project.this.id
  parent_id  = neon_project.this.default_branch_id
  name       = "mybranch"
}

resource "neon_endpoint" "this" {
  project_id = neon_project.this.id
  branch_id  = neon_branch.this.id

  autoscaling_limit_min_cu = 0.25
  autoscaling_limit_max_cu = 1
}

resource "neon_role" "this" {
  project_id = neon_project.this.id
  branch_id  = neon_branch.this.id
  name       = "myrole"
}

resource "neon_database" "this" {
  project_id = neon_project.this.id
  branch_id  = neon_branch.this.id
  owner_name = neon_role.this.name
  name       = "mydb"
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "neon/mybranch/mydb/myrole"
  description             = "Neon SaaS db access details"
  recovery_window_in_days = 0

  tags = {
    "project"  = "demo"
    "platform" = "neon"
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    host     = neon_endpoint.this.host
    user     = neon_role.this.name
    password = neon_role.this.password
    database = neon_database.this.name
  })
}

data "aws_iam_policy_document" "neon_access_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    resources = [
      aws_secretsmanager_secret_version.this.arn,
    ]
  }
}

resource "aws_iam_policy" "neon_access_secret" {
  name   = "mybranch-mydb-myrole"
  path   = "/neon/read-only/"
  policy = data.aws_iam_policy_document.neon_access_secret.json
}
