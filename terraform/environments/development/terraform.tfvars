environment          = "dev"
cluster_name         = "labeks-development-dev"
vpc_cidr             = "10.20.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
single_nat_gateway   = true

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "development"
  ManagedBy = "terraform"
}
