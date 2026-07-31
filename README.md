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
- [ ] Terraform: módulos reutilizables (`networking`, `eks-cluster`)
- [ ] Terraform: stacks `deployment-cluster` y `development-cluster` (con `dev`/`qa`/`prd`)
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

Pendiente — se documenta a medida que cada fase de la lista anterior se completa.

## Cómo validar que el secreto llegó al microservicio

Pendiente — se documenta junto con el microservicio y el pipeline (fases correspondientes).
