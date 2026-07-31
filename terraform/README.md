# Terraform

Diseño modular: los recursos reutilizables viven en `modules/`, cada clúster tiene su propio
stack raíz en `infrastructure/`, y los valores que cambian por ambiente viven en `environments/`.

```
terraform/
├── modules/
│   ├── networking/        # VPC, subredes públicas/privadas, IGW, NAT
│   └── eks-cluster/        # Cluster EKS, node group administrado, IAM, proveedor OIDC (IRSA)
├── infrastructure/
│   ├── deployment-cluster/     # Stack para el clúster de Jenkins + Vault
│   └── development-cluster/    # Stack para el clúster que corre el microservicio
└── environments/
    ├── deployment/terraform.tfvars
    └── development/
        ├── dev/terraform.tfvars
        ├── qa/terraform.tfvars
        └── prd/terraform.tfvars
```

`deployment-cluster` es un único ambiente (Jenkins/Vault no se replican por env). `development-cluster`
es el mismo stack aplicado tres veces con distinto `-var-file`, para poder escalar a dev/qa/prd sin
duplicar código.

## Uso

```bash
cd terraform/infrastructure/deployment-cluster
terraform init
terraform validate
terraform plan -var-file=../../environments/deployment/terraform.tfvars

cd ../development-cluster
terraform init
terraform validate
terraform plan -var-file=../../environments/development/dev/terraform.tfvars
```

Por ahora el backend es local (`backend.tf` en cada stack) y no se ha corrido ningún
`apply`: son solo `fmt`/`validate`/`plan` mientras se confirma la cuenta de AWS de destino
y el rol de Azure DevOps en el flujo. El backend remoto (S3 + locking) se migra cuando eso
esté definido — ver el `TODO` en cada `backend.tf`.
