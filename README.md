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
│   └── environments/       # terraform.tfvars de deployment y development
├── microservice/           # Spring Boot 3, Java 21
├── k8s/                    # manifiestos de ambos clústeres (namespaces, RBAC, Deployment, Vault)
├── jenkins/                # Jenkinsfile y política de Vault
└── docs/                   # diagrama de arquitectura y flujo CI/CD
```

## Estado de avance

- [x] Bootstrap del repositorio (`.gitignore`, estructura de carpetas)
- [x] Terraform: módulos reutilizables (`networking`, `eks-cluster`)
- [x] Terraform: stacks `deployment-cluster` y `development-cluster`
- [x] Microservicio Java 21 (endpoints `/env-secret` y `/config-property`, Dockerfile)
- [x] Manifiestos Kubernetes del clúster `development` (namespace, RBAC, Deployment, Service)
- [x] Jenkins + Vault en el clúster `deployment` (Helm values, política de Vault)
- [x] Jenkinsfile (build → push → deploy → rollback)
- [x] Extras: CronJob de auditoría de eventos del kubelet, CRD `MicroserviceConfig`
- [ ] Documentación final: instrucciones paso a paso, validación del secreto, capturas, diagrama

> Nota: los dos clústeres se despliegan sobre AWS EKS reutilizando una VPC ya existente en la
> cuenta disponible (sin tocar lo que ya hay ahí — ver `terraform/README.md`). El registry es
> ECR de la misma cuenta. Vault corre en el clúster `deployment` y el clúster `development` lo
> alcanza por un Load Balancer interno (nunca expuesto a internet); el secreto llega al
> microservicio vía Vault Secrets Operator, con el CSI provider documentado como alternativa.
> Sigue pendiente el backend remoto de state (S3) y el `apply` real, que se hace manual desde
> consola/CLI cuando se decida levantar la infraestructura de verdad — **nada se ha desplegado
> todavía**, todo lo de arriba está escrito y validado (`plan`, `helm template`, `kubeconform`,
> tests), no aplicado contra AWS.

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

El resto de los pasos (Jenkins, Vault, manifiestos K8s) se documentan según avanza el
checklist de arriba.

### Microservicio (local)

Requiere Java 21 y Maven (probado con Temurin 21.0.12 + Maven 3.9.16):

```bash
cd microservice
mvn clean verify        # compila y corre los 4 tests (unitarios + contexto Spring Boot)

# arrancarlo simulando el secreto que inyectaría el pipeline:
VAULT_SECRET="mi-secreto-de-vault" mvn spring-boot:run
```

O con Docker (build multi-stage, corre como usuario no-root):

```bash
docker build -t labeks-microservice:local .
docker run --rm -p 8080:8080 -e VAULT_SECRET="mi-secreto-de-vault" labeks-microservice:local
```

## Cómo validar que el secreto llegó al microservicio

Con la app corriendo (local o en Docker, ver arriba):

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP","groups":["liveness","readiness"]}

curl http://localhost:8080/api/env-secret
# {"envVarName":"VAULT_SECRET","value":"mi-secreto-de-vault"}

curl http://localhost:8080/api/config-property
# {"property":"app.config.message","value":"configuracion-local-por-defecto"}
```

Si `VAULT_SECRET` no está definida, `value` responde `"(no inyectada)"` en vez de fallar —
así se puede distinguir "el pipeline no inyectó nada" de un error real. Cuando el pipeline de
Jenkins y los manifiestos de Kubernetes estén listos, esta misma verificación se hace contra
el Load Balancer del clúster `development` en vez de `localhost`.
