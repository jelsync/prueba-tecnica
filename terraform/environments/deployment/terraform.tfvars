cluster_name         = "labeks-deployment"
vpc_cidr             = "10.10.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
single_nat_gateway   = true

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "deployment"
  ManagedBy = "terraform"
}
