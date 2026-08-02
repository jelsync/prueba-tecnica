#!/usr/bin/env bash
# Segundo mount de autenticación Kubernetes en el MISMO Vault (corre en el
# clúster deployment), esta vez para que el Vault Secrets Operator (VSO) del
# clúster development pueda leer el secreto y sincronizarlo como Secret
# nativo de k8s. Se usa un mount separado del de Jenkins
# (jenkins/vault-k8s-auth-setup.sh) porque cada clúster tiene su propia API
# de Kubernetes/CA — Vault necesita configurarlos por separado.
#
# Se corre UNA SOLA VEZ, después de Vault Y del clúster development ya
# desplegados. Requiere: `vault login` contra VAULT_ADDR, y kubectl con un
# contexto apuntando al clúster development (no al de deployment).
set -euo pipefail

: "${VAULT_ADDR:?export VAULT_ADDR primero}"

echo "==> Habilitando el método de autenticación Kubernetes en su propio mount"
vault auth list -format=json | grep -q '"kubernetes-development/"' || vault auth enable -path=kubernetes-development kubernetes

echo "==> Configurando el auth method contra la API del clúster development"
KUBE_HOST=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
KUBE_CA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)

# Vault corre en el clúster deployment; para validar tokens de development
# necesita un reviewer JWT que sea válido EN development (ServiceAccount con
# system:auth-delegator, ver token-reviewer.yaml) y desactivar el uso de su
# token/CA local. Sin esto la TokenReview cross-cluster falla con "403
# permission denied" (confirmado en vivo con el login de VSO).
REVIEWER_JWT=$(kubectl -n development get secret vault-token-reviewer-token -o jsonpath='{.data.token}' | base64 -d)

vault write auth/kubernetes-development/config \
  kubernetes_host="${KUBE_HOST}" \
  kubernetes_ca_cert="${KUBE_CA}" \
  token_reviewer_jwt="${REVIEWER_JWT}" \
  disable_local_ca_jwt=true

echo "==> Reutilizando la misma política de solo lectura que usa Jenkins"
vault policy write microservice-read ../../../jenkins/vault-policy.hcl

echo "==> Creando el role que liga la ServiceAccount 'microservice' a esa política"
vault write auth/kubernetes-development/role/development-microservice \
  bound_service_account_names=microservice \
  bound_service_account_namespaces=development \
  policies=microservice-read \
  ttl=15m

cat <<'EOF'

Listo. Falta aplicar los CRDs de VSO (connection.yaml, auth.yaml,
static-secret.yaml) contra el clúster development una vez el Vault Secrets
Operator esté instalado (helm install vault-secrets-operator
hashicorp/vault-secrets-operator -n vault-secrets-operator-system --create-namespace).

EOF
