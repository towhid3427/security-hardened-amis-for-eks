provider "aws" {
  region = local.region
}
module "vpc" {
  source = "./../modules/vpc"
  name   = local.name
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
}
