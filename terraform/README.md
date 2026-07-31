# Terraform

Diseño modular: los recursos reutilizables viven en `modules/`, cada clúster tiene su propio
stack raíz en `infrastructure/`, y los valores que cambian por ambiente viven en `environments/`.

```
terraform/
├── modules/
│   ├── networking/         # Crea una VPC nueva (VPC, subredes, IGW, NAT) — no se usa hoy, ver abajo
│   ├── existing-network/   # Solo lee (data sources) una VPC/subredes ya existentes — el que sí se usa
│   └── eks-cluster/        # Cluster EKS, node group administrado, IAM, proveedor OIDC (IRSA)
├── infrastructure/
│   ├── deployment-cluster/     # Stack para el clúster de Jenkins + Vault
│   └── development-cluster/    # Stack para el clúster que corre el microservicio
└── environments/
    ├── deployment/
    │   ├── terraform.tfvars                    # ajustes propios (versionado)
    │   └── network.auto.tfvars.example          # plantilla de los IDs de red (real va sin versionar)
    └── development/
        ├── terraform.tfvars
        └── network.auto.tfvars.example
```

Un `terraform.tfvars` por clúster: el laboratorio pide exactamente dos (deployment y development),
así que se dejó así de simple en vez de sobre-diseñar una separación dev/qa/prd que no aporta aquí.

### ¿Por qué hay dos módulos de red?

La cuenta de AWS disponible para este laboratorio ya tiene otra infraestructura desplegada (de otro
equipo). Por eso `deployment-cluster` y `development-cluster` usan `existing-network` — que **nunca
crea, modifica ni importa nada**, solo lee vía `data` la VPC y las subredes ya existentes — en vez de
`networking` (que sí crea una VPC nueva y se dejó como módulo genérico reutilizable para otro
escenario, p. ej. una cuenta propia y aislada). Los dos clústeres comparten la misma VPC/subredes
para que Jenkins pueda llegar a la API del clúster de development.

Los identificadores reales (VPC ID, subnet IDs) **no se versionan** — viven en
`environments/<stack>/network.auto.tfvars` (gitignored, Terraform lo carga automático por el sufijo
`.auto.tfvars`) y solo se documenta la forma con el `.example` correspondiente.

## Uso

```bash
cd terraform/infrastructure/deployment-cluster
cp ../../environments/deployment/network.auto.tfvars.example ../../environments/deployment/network.auto.tfvars
# editar network.auto.tfvars con los IDs reales de tu VPC/subredes

terraform init
terraform validate
terraform plan \
  -var-file=../../environments/deployment/terraform.tfvars \
  -var-file=../../environments/deployment/network.auto.tfvars

cd ../development-cluster
cp ../../environments/development/network.auto.tfvars.example ../../environments/development/network.auto.tfvars
# mismo VPC ID / subnet IDs que en deployment

terraform init
terraform validate
terraform plan \
  -var-file=../../environments/development/terraform.tfvars \
  -var-file=../../environments/development/network.auto.tfvars
```

Ambos `plan` ya se corrieron contra la cuenta real (con credenciales de solo lectura vía SSO): 9
recursos nuevos a crear en cada stack (IAM roles, cluster EKS, node group, proveedor OIDC), 0 cambios
y 0 destrucciones — nada de lo ya desplegado se toca.

Por ahora el backend es local (`backend.tf` en cada stack) y no se ha corrido ningún `apply`
todavía. El backend remoto (S3 + locking nativo) se migra cuando el bucket dedicado para el state
de este laboratorio esté creado — ver el `TODO` en cada `backend.tf`.
