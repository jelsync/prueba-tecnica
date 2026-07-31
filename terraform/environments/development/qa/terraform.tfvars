environment          = "qa"
cluster_name         = "labeks-development-qa"
vpc_cidr             = "10.21.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.21.0.0/24", "10.21.1.0/24"]
private_subnet_cidrs = ["10.21.10.0/24", "10.21.11.0/24"]
single_nat_gateway   = true

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "development"
  ManagedBy = "terraform"
}
