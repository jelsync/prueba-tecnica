environment  = "dev"
cluster_name = "labeks-development-dev"

# existing_vpc_id / existing_public_subnet_ids / existing_private_subnet_ids
# viven en network.auto.tfvars (sin versionar) — ver network.auto.tfvars.example.

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "development"
  ManagedBy = "terraform"
}
