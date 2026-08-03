cluster_name = "labeks-deployment"

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

tags = {
  Project   = "labeks-devops-2026"
  Cluster   = "deployment"
  ManagedBy = "terraform"
}
