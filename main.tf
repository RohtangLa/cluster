
terraform {
  required_version = ">= 0.12"
}

locals {
     cluster_name ="first-kube"
     region = "us-east-1"
     vpc_name = "kube"
     vpc_cidr = "10.0.0.0/24"
}

module "vpc" {
    source = "github.com/RohtangLa/terraform-aws-vpc"
    aws_region = "us-east-1"
    aws_zones = ["us-east-1a","us-east-1b","us-east-1c"]
    vpc_name = "${local.vpc_name}"
    vpc_cidr = "${local.vpc_cidr}"
    private_subnets = "true"
    tags = merge(
    {
      "Name"                                               = "${local.vpc_name}"
      format("kubernetes.io/cluster/%v", "${local.cluster_name}") = "owned"
    }
  )
}

module "kubernetes" {
 source ="github.com/RohtangLa/terraform-aws-kubernetes"
 aws_region = "us-east-1"
 cluster_name = "${local.cluster_name}"I 
 master_instance_type = "t2.medium"
 worker_instance_type = "t2.medium"
 ssh_public_key       = "~/.ssh/id_rsa.pub"
 ssh_access_cidr      = ["0.0.0.0/0"]
 api_access_cidr      = ["0.0.0.0/0"]
 min_worker_count     = 2
 max_worker_count     = 3
 hosted_zone          = "learningcloud.com"
 hosted_zone_private  = "false"

 master_subnet_id = module.vpc.subnet_ids[0]
 worker_subnet_ids = [
     module.vpc.subnet_ids[0],
     module.vpc.subnet_ids[1],
     module.vpc.subnet_ids[2]
 ]

tags = {
    Application = "AWS-Kubernetes"
  }

  # Tags in a different format for Auto Scaling Group
  tags2 = [
    {
      key                 = "Application"
      value               = "AWS-Kubernetes"
      propagate_at_launch = true
    },
  ]

  addons =[]
}
