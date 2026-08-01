# Manifiestos y Helm values — clúster `deployment`

```
namespaces.yaml                        # namespaces "jenkins" y "vault"
jenkins/
├── values.yaml                        # Helm values del chart jenkins/jenkins
└── vault-auth-serviceaccount.yaml     # identidad que Jenkins presenta a Vault
vault/
├── values.yaml                        # Helm values del chart hashicorp/vault
└── service-internal-lb.yaml           # NLB interno para acceso cross-cluster
```

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
```

Después de que Vault esté **inicializado y unsealed** (paso manual, `vault operator init` /
`unseal` — no lo hace este repo):

```bash
export VAULT_ADDR=http://localhost:8200   # con port-forward al Service de vault
vault login                                # con el root token de la inicialización
cd ../../jenkins && ./vault-k8s-auth-setup.sh
```

## Por qué un Service aparte para Vault

El chart `hashicorp/vault` (`server.service`) solo soporta `ClusterIP`/`NodePort` — no
`LoadBalancer` (confirmado con `helm show values hashicorp/vault`). Como el clúster
`development` es un EKS distinto (aunque comparta la misma VPC), un `ClusterIP` del clúster
`deployment` no es alcanzable desde ahí. `vault/service-internal-lb.yaml` es un Service propio
que selecciona los mismos pods del `StatefulSet` del chart, expuesto solo dentro de la VPC
(`internal`, nunca a internet).
