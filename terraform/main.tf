provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.env_name}-"
}

module "ssh" {
  source       = "./ssh"
  ssh_key_name = "${random_id.environment_name.hex}"
}

module "hashistack-instance-profile" {
  region           = "us-east-1"
  source           = "./instance-policy"
  environment_name = "${random_id.environment_name.hex}"
  kms_arn          = "${aws_kms_key.vault.arn}"
}

module "vpc-east" {
  providers = {
    aws = "aws.east"
  }

  source                           = "terraform-aws-modules/vpc/aws"
  name                             = "${random_id.environment_name.hex}-east"
  cidr                             = "10.0.0.0/16"
  azs                              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets                  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets                   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway               = true
  enable_vpn_gateway               = false
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "service.consul"
  dhcp_options_domain_name_servers = ["127.0.0.1", "169.254.169.253"]

  tags = {
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

module "vpc-west" {
  providers = {
    aws = "aws.west"
  }

  source                           = "terraform-aws-modules/vpc/aws"
  name                             = "${random_id.environment_name.hex}-west"
  cidr                             = "172.16.0.0/16"
  azs                              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets                  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets                   = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
  enable_nat_gateway               = true
  enable_vpn_gateway               = false
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "service.consul"
  dhcp_options_domain_name_servers = ["127.0.0.1", "169.254.169.253"]

  tags = {
    owner = "${var.owner}"
    TTL   = "${var.ttl}"
  }
}

locals {
  ssh_user_map = "${map("ubuntu","ubuntu","rhel","ec2-user")}"
}

module "hashistack-us-east" {
  source                   = "./hashistack"
  owner                    = "${var.owner}"
  ttl                      = "${var.ttl}"
  region                   = "us-east-1"
  cluster_name             = "${random_id.environment_name.hex}-us-east-1"
  environment_name         = "${random_id.environment_name.hex}"
  remote_regions           = ["us-west-2"]
  instance_profile         = "${module.hashistack-instance-profile.policy}"
  ssh_key_name             = "${random_id.environment_name.hex}-us-east"
  public_key_data          = "${module.ssh.public_key_data}"
  private_key_data         = "${module.ssh.private_key_data}"
  subnet_ids               = "${module.vpc-east.private_subnets}"
  public_subnet_ids        = "${module.vpc-east.public_subnets}"
  vpc_id                   = "${module.vpc-east.vpc_id}"
  kms_id                   = "${aws_kms_key.vault.key_id}"
  ssh_user_name            = "${lookup(local.ssh_user_map,var.operation_system)}"
  operating_system         = "${var.operating_system}"
  operating_system_version = "${var.operating_system_version}"
}

module "hashistack-us-west" {
  source                   = "./hashistack"
  owner                    = "${var.owner}"
  ttl                      = "${var.ttl}"
  region                   = "us-west-2"
  cluster_name             = "${random_id.environment_name.hex}-us-west-2"
  environment_name         = "${random_id.environment_name.hex}"
  remote_regions           = ["us-east-1"]
  instance_profile         = "${module.hashistack-instance-profile.policy}"
  ssh_key_name             = "${random_id.environment_name.hex}-us-west"
  public_key_data          = "${module.ssh.public_key_data}"
  private_key_data         = "${module.ssh.private_key_data}"
  subnet_ids               = "${module.vpc-west.private_subnets}"
  public_subnet_ids        = "${module.vpc-west.public_subnets}"
  vpc_id                   = "${module.vpc-west.vpc_id}"
  kms_id                   = "${aws_kms_key.vault.key_id}"
  ssh_user_name            = "${lookup(local.ssh_user_map,var.operating_system)}"
  operating_system         = "${var.operating_system}"
  operating_system_version = "${var.operating_system_version}"
}

module "admin-east" {
  source                           = "./admin"
  owner                            = "${var.owner}"
  ttl                              = "${var.ttl}"
  region                           = "us-east-1"
  cluster_name                     = "${random_id.environment_name.hex}-us-east-1"
  environment_name                 = "${random_id.environment_name.hex}"
  remote_regions                   = ["us-west-2"]
  ssh_key_name                     = "${random_id.environment_name.hex}-admin"
  instance_profile                 = "${module.hashistack-instance-profile.policy}"
  public_key_data                  = "${module.ssh.public_key_data}"
  private_key_data                 = "${module.ssh.private_key_data}"
  subnet_ids                       = "${module.vpc-east.public_subnets}"
  vpc_id                           = "${module.vpc-east.vpc_id}"
  vault_cloud_auto_init_and_unseal = "${var.vault_cloud_auto_init_and_unseal}"
  vault_auto_replication_setup     = "${var.vault_auto_replication_setup}"
  ssh_user_name                    = "${lookup(local.ssh_user_map,var.operating_system)}"
  operating_system                 = "${var.operating_system}"
  operating_system_version         = "${var.operating_system_version}"
  aws_auth_access_key              = "${aws_iam_access_key.vault.id}"
  aws_auth_secret_key              = "${aws_iam_access_key.vault.secret}"
  hashistack_instance_arn          = "${module.hashistack-instance-profile.hashistack_instance_arn}"
}
