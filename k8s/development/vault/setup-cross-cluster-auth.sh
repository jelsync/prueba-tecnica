#!/usr/bin/env bash
# Configura, de forma robusta y usando SOLO kubectl (no requiere la CLI de
# vault en tu maquina), el auth Kubernetes cross-cluster que necesita el
# Vault Secrets Operator (VSO), y deja la cadena VSO lista para sincronizar.
#
# Automatiza los dos pasos que historicamente daban problemas al re-desplegar:
#   1. Poner el DNS ACTUAL del NLB interno de Vault en connection.yaml
#      (ese DNS cambia cada vez que se recrea el Service de Vault).
#   2. Cargar el reviewer JWT + CA del cluster development dentro del pod de
#      Vault sin que se corrompa (kubectl exec -i no entrega la ultima linea
#      si no termina en salto de linea -> se fuerza el flush y se limpia).
#
# Requisitos: kubectl con dos contextos (deployment y development), Vault ya
# inicializado y unsealed. El root token se pasa por variable de entorno para
# no dejarlo en el historial ni imprimirlo:
#
#   export VAULT_ROOT_TOKEN=<root-token>      # se usa, nunca se imprime
#   ./setup-cross-cluster-auth.sh
#
# Contextos configurables (por si tus --alias son otros):
#   DEPLOY_CTX (default: deployment)   DEV_CTX (default: development)
set -euo pipefail

DEPLOY_CTX="${DEPLOY_CTX:-deployment}"
DEV_CTX="${DEV_CTX:-development}"
HERE="$(dirname "$0")"
: "${VAULT_ROOT_TOKEN:?export VAULT_ROOT_TOKEN con el root token de Vault (no se imprime)}"

echo "==> 1/5 Aplicando la ServiceAccount reviewer (system:auth-delegator) en development"
kubectl --context "$DEV_CTX" apply -f "$HERE/token-reviewer.yaml"

echo "==> 2/5 Esperando a que el token del reviewer se poblee"
for _ in $(seq 1 15); do
  LEN=$(kubectl --context "$DEV_CTX" -n development get secret vault-token-reviewer-token \
        -o jsonpath='{.data.token}' 2>/dev/null | wc -c)
  [ "${LEN:-0}" -gt 100 ] && break
  sleep 2
done

DEV_HOST=$(kubectl --context "$DEV_CTX" config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "    API de development: $DEV_HOST"

echo "==> 3/5 Cargando reviewer JWT y CA dentro del pod vault-0 (metodo a prueba de flush)"
# El '; echo' fuerza el flush del stdin (sin un salto final, kubectl exec -i
# no entrega la ultima linea); 'tr -d' quita ese salto para no corromper el JWT.
{ kubectl --context "$DEV_CTX" -n development get secret vault-token-reviewer-token \
    -o jsonpath='{.data.token}' | base64 -d; echo; } \
  | kubectl --context "$DEPLOY_CTX" -n vault exec -i vault-0 -c vault -- sh -c "tr -d '\n\r' > /tmp/reviewer.jwt"
kubectl --context "$DEV_CTX" -n development get secret vault-token-reviewer-token \
    -o jsonpath='{.data.ca\.crt}' | base64 -d \
  | kubectl --context "$DEPLOY_CTX" -n vault exec -i vault-0 -c vault -- sh -c "cat > /tmp/dev-ca.crt"

echo "==> 4/5 Escribiendo config (reviewer + disable_local_ca_jwt) y role (audience=vault)"
kubectl --context "$DEPLOY_CTX" -n vault exec -i vault-0 -c vault -- sh -s <<EOF
set -e
export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
vault auth list -format=json | grep -q '"kubernetes-development/"' \
  || vault auth enable -path=kubernetes-development kubernetes
vault write auth/kubernetes-development/config \
  kubernetes_host="$DEV_HOST" \
  kubernetes_ca_cert=@/tmp/dev-ca.crt \
  token_reviewer_jwt=@/tmp/reviewer.jwt \
  disable_local_ca_jwt=true
vault write auth/kubernetes-development/role/development-microservice \
  bound_service_account_names=microservice \
  bound_service_account_namespaces=development \
  audience=vault \
  policies=microservice-read \
  ttl=15m
rm -f /tmp/reviewer.jwt /tmp/dev-ca.crt
EOF

echo "==> 5/5 Aplicando los CRDs de VSO con el DNS actual del NLB interno de Vault"
VAULT_LB=$(kubectl --context "$DEPLOY_CTX" -n vault get svc vault-internal-lb \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
[ -n "$VAULT_LB" ] || { echo "ERROR: el Service vault-internal-lb aun no tiene EXTERNAL-IP"; exit 1; }
echo "    NLB interno de Vault: $VAULT_LB"
sed "s|<VAULT_INTERNAL_LB_ADDRESS>|$VAULT_LB|" "$HERE/connection.yaml" | kubectl --context "$DEV_CTX" apply -f -
kubectl --context "$DEV_CTX" apply -f "$HERE/auth.yaml"
kubectl --context "$DEV_CTX" apply -f "$HERE/static-secret.yaml"

cat <<'EOF'

Listo. Verifica que VSO sincronizo (SYNCED debe pasar a True en ~30s):

  kubectl --context development -n development get vaultstaticsecret microservice-secret

Si sigue en False, revisa el Message con:
  kubectl --context development -n development describe vaultstaticsecret microservice-secret
EOF
