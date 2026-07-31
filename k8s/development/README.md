# Manifiestos — clúster `development`

```
namespace.yaml        # namespace "development"
serviceaccount.yaml   # service account del microservicio (sin automount de token)
rbac.yaml              # Role + RoleBinding: solo lectura de configmaps/secrets en su namespace
deployment.yaml        # 2 réplicas, probes de Actuator, resources, filesystem read-only
service.yaml            # LoadBalancer (NLB internet-facing vía AWS Load Balancer Controller)
```

## Placeholders que hay que resolver antes de aplicar

Estos manifiestos están completos y validados, pero tienen dos valores marcados a propósito
como placeholder porque dependen de infraestructura que aún no existe / de identificadores
reales que no se versionan:

- `deployment.yaml` → `image: "<ECR_REPOSITORY_URI>:latest"`: lo resuelve el Jenkinsfile en el
  deploy (Fase Jenkins), apuntando al repositorio ECR real.
- `service.yaml` → `service.beta.kubernetes.io/aws-load-balancer-subnets`: reemplazar con los
  IDs reales de las subredes públicas (salida `public_subnet_ids` del stack de Terraform —
  ver `terraform/README.md`). Nunca commitear esos IDs aquí.

## Prerrequisito: AWS Load Balancer Controller

`service.yaml` fija las subredes por anotación en vez de por tags (a propósito: no se
etiquetaron las subredes existentes de la VPC compartida). Eso solo lo entiende el **AWS Load
Balancer Controller** (instalado vía Helm), no el proveedor in-tree legacy de EKS. Falta
agregar su instalación al roadmap del clúster `development`.

## Validar sin un clúster real

`kubectl apply --dry-run=client` igual necesita contactar a un API server para resolver los
tipos de recurso, así que no sirve sin clúster. Se usó
[kubeconform](https://github.com/yannh/kubeconform) (binario único, sin instalación) contra el
esquema oficial de Kubernetes 1.31 (misma versión que el EKS de este laboratorio):

```bash
kubeconform -strict -summary -kubernetes-version 1.31.0 *.yaml
# Summary: 6 resources found in 5 files - Valid: 6, Invalid: 0, Errors: 0, Skipped: 0
```
