provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {
  type = string
  default = ""
}
variable "aws_secret_key" {
  type = string
  default = ""
}

variable "vpc_config" {
  type = map(object({
    cidr_block           = string
    availability_zones   = list(string)
    environment          = string
  }))

  default = {
    dev = {
      cidr_block         = "10.0.0.0/16"
      availability_zones = ["us-east-1a", "us-east-1b"]
      environment        = "development"
    }

    staging = {
      cidr_block         = "10.1.0.0/16"
      availability_zones = ["us-east-1a", "us-east-1b"]
      environment        = "staging"
    }

    prod = {
      cidr_block         = "10.2.0.0/16"
      availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
      environment        = "production"
    }
  }
}

resource "aws_vpc" "vpc" {
  for_each = var.vpc_config

  cidr_block = each.value.cidr_block
  tags = {
    Name        = "${each.key}-vpc"
    Environment = each.value.environment
  }
}

resource "aws_subnet" "subnet" {
  for_each = { for vpc_key, vpc_value in var.vpc_config : vpc_key => vpc_value }

  availability_zone = each.value.availability_zones[0] # Example for first subnet per VPC, can be modified
  vpc_id            = aws_vpc.vpc[each.key].id
  cidr_block        = cidrsubnet(each.value.cidr_block, 8, 0)

  tags = {
    Name        = "${each.key}-subnet-1"
    Environment = each.value.environment
  }
}

output "vpc_ids" {
  value = values(aws_vpc.vpc)[*].id
}
