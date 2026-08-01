# Manifiestos y Helm values — clúster `deployment`

```
namespaces.yaml                        # namespaces "jenkins" y "vault"
jenkins/
├── values.yaml                        # Helm values del chart jenkins/jenkins (+ credencial Vault por JCasC)
├── vault-auth-serviceaccount.yaml     # identidad que Jenkins presenta a Vault
├── build-agent-serviceaccount.yaml    # IRSA: agente que hace push a ECR
└── deploy-agent-serviceaccount.yaml   # IRSA: agente que despliega en development
vault/
├── values.yaml                        # Helm values del chart hashicorp/vault
└── service-internal-lb.yaml           # NLB interno para acceso cross-cluster
```

El repositorio ECR y los dos roles IRSA (`jenkins-ecr-push`, `jenkins-deploy`) los crea
Terraform (`terraform/modules/ecr`, `terraform/infrastructure/deployment-cluster/jenkins-deploy-role.tf`),
no este directorio — los ARN reales se anotan en los dos `*-agent-serviceaccount.yaml` después
del `apply` (salidas `ecr_push_role_arn` / `jenkins_deploy_role_arn`).

Todo esto se validó con `helm template` contra los charts oficiales reales (no valores
adivinados) y `kubeconform`/inspección de los recursos renderizados — sin desplegar nada.

## Instalación (cuando el clúster exista)

```bash
kubectl apply -f namespaces.yaml

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install vault hashicorp/vault -n vault -f vault/values.yaml
kubectl apply -f vault/service-internal-lb.yaml   # con los IDs reales de subred ya puestos

helm install jenkins jenkins/jenkins -n jenkins -f jenkins/values.yaml
kubectl apply -f jenkins/vault-auth-serviceaccount.yaml
kubectl apply -f jenkins/build-agent-serviceaccount.yaml   # con el ARN real de ecr_push_role_arn
kubectl apply -f jenkins/deploy-agent-serviceaccount.yaml  # con el ARN real de jenkins_deploy_role_arn
```

Después de que Vault esté **inicializado y unsealed** (paso manual, `vault operator init` /
`unseal` — no lo hace este repo):

```bash
export VAULT_ADDR=http://localhost:8200   # con port-forward al Service de vault
vault login                                # con el root token de la inicialización
cd ../../jenkins && ./vault-k8s-auth-setup.sh
```

## El pipeline (`jenkins/Jenkinsfile`)

Dos agentes de Kubernetes, cada uno con su propia identidad IRSA (mínimo privilegio):

1. **Build**: lee `secret/microservice` de Vault (mount `kubernetes-jenkins`), lo deja como
   `VAULT_SECRET` disponible *antes* del build (tal como pide el enunciado), construye la
   imagen y la publica en ECR con `jenkins-ecr-push`.
2. **Deploy**: con `jenkins-deploy`, actualiza el `Deployment` del clúster `development` y hace
   `rollout undo` automático si el `rollout status` falla.

Validado contra el linter real de Jenkins (`/pipeline-model-converter/validate` en un
contenedor `jenkins/jenkins` temporal) — encontró un plugin faltante (`timestamper`) antes de
pasar limpio.

## Por qué un Service aparte para Vault

El chart `hashicorp/vault` (`server.service`) solo soporta `ClusterIP`/`NodePort` — no
`LoadBalancer` (confirmado con `helm show values hashicorp/vault`). Como el clúster
`development` es un EKS distinto (aunque comparta la misma VPC), un `ClusterIP` del clúster
`deployment` no es alcanzable desde ahí. `vault/service-internal-lb.yaml` es un Service propio
que selecciona los mismos pods del `StatefulSet` del chart, expuesto solo dentro de la VPC
(`internal`, nunca a internet).
