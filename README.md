# Laboratorio DevOps 2026 — Clústeres EKS Deployment & Development

Solución de infraestructura automatizada (IaC) que levanta dos clústeres de Kubernetes:

- **`deployment`**: Jenkins + Vault. El pipeline lee un secreto de Vault, lo inyecta como
  variable de entorno antes del build, construye la imagen del microservicio, la sube a un
  container registry y la despliega en el clúster `development`.
- **`development`**: expone el microservicio (Java 21, 2 réplicas) detrás de un Load Balancer.

## Arquitectura (alto nivel)

```
                 ┌─────────────────────────┐        push image        ┌──────────────────────────┐
                 │   Clúster "deployment"   │ ────────────────────────▶│    Container Registry     │
                 │                          │                           └──────────────────────────┘
                 │  Jenkins ───▶ lee secreto│
                 │      │        de Vault   │        deploy (kubectl/helm)
                 │      ▼                   │ ─────────────────────────────────────┐
                 │    build + push imagen   │                                       ▼
                 └─────────────────────────┘                         ┌──────────────────────────┐
                                                                      │  Clúster "development"    │
                                                                      │                            │
                                                                      │  LoadBalancer              │
                                                                      │   └── microservicio ×2     │
                                                                      │        /env-secret         │
                                                                      │        /config-property    │
                                                                      └──────────────────────────┘
```

El diagrama detallado (Mermaid) y la explicación completa del flujo CI/CD viven en
[`docs/architecture.md`](docs/architecture.md) (pendiente, ver checklist abajo).

## Estructura del repositorio

```
LabEks/
├── terraform/
│   ├── modules/            # networking y eks-cluster: reutilizables entre ambos clústeres
│   ├── infrastructure/     # stacks raíz: deployment-cluster y development-cluster
│   └── environments/       # valores por ambiente (deployment; development/{dev,qa,prd})
├── microservice/           # Spring Boot 3, Java 21
├── k8s/                    # manifiestos de ambos clústeres (namespaces, RBAC, Deployment, Vault)
├── jenkins/                # Jenkinsfile y política de Vault
└── docs/                   # diagrama de arquitectura y flujo CI/CD
```

## Estado de avance

- [x] Bootstrap del repositorio (`.gitignore`, estructura de carpetas)
- [x] Terraform: módulos reutilizables (`networking`, `eks-cluster`)
- [x] Terraform: stacks `deployment-cluster` y `development-cluster` (con `dev`/`qa`/`prd`)
- [ ] Microservicio Java 21 (endpoints `/env-secret` y `/config-property`, Dockerfile)
- [ ] Manifiestos Kubernetes del clúster `development` (namespace, RBAC, Deployment, Service)
- [ ] Jenkins + Vault en el clúster `deployment` (Helm values, política de Vault)
- [ ] Jenkinsfile (build → push → deploy → rollback)
- [ ] Extras: CronJob de auditoría de eventos del kubelet, CRD `MicroserviceConfig`
- [ ] Documentación final: instrucciones paso a paso, validación del secreto, capturas, diagrama

> Nota: por ahora el trabajo se limita a lo que no requiere una cuenta de nube activa
> (código, no despliegue real). El `terraform apply`, el backend remoto de state y el
> registry definitivo quedan pendientes de confirmar infraestructura de destino.

## Cómo levantar el laboratorio

Por ahora solo está listo el código Terraform (sin `apply`, ver [`terraform/README.md`](terraform/README.md)
para el detalle de módulos y stacks):

```bash
cd terraform/infrastructure/deployment-cluster
terraform init
terraform validate

cd ../development-cluster
terraform init
terraform validate
```

El resto de los pasos (Jenkins, Vault, microservicio, manifiestos K8s) se documentan
según avanza el checklist de arriba.

## Cómo validar que el secreto llegó al microservicio

Pendiente — se documenta junto con el microservicio y el pipeline (fases correspondientes).
