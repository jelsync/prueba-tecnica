environment          = "prd"
cluster_name         = "labeks-development-prd"
vpc_cidr             = "10.22.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.22.0.0/24", "10.22.1.0/24", "10.22.2.0/24"]
private_subnet_cidrs = ["10.22.10.0/24", "10.22.11.0/24", "10.22.12.0/24"]
single_nat_gateway   = false # un NAT por AZ: mayor disponibilidad para el ambiente productivo

node_instance_types = ["t3.large"]
node_desired_size   = 3
node_min_size       = 3
node_max_size       = 6

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "development"
  ManagedBy = "terraform"
}
