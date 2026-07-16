terraform {
  required_version = ">= 1.9"

  # Providers are Terraform's plugins: the `aws` provider translates resource
  # blocks into AWS API calls. Version-pinned like any dependency (the exact
  # resolved version lands in .terraform.lock.hcl — commit that file).
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # M0: state stays local (single developer, one small stack).
  # Remote S3 backend is parked in BACKLOG.md.
}

provider "aws" {
  region = var.region

  # Stamped onto every resource this configuration creates: makes "what is
  # this and who owns it" answerable in the AWS console six months from now.
  default_tags {
    tags = {
      Project   = "trianglobe"
      ManagedBy = "terraform"
    }
  }
}
