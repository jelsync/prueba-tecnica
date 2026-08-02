#!/usr/bin/env bash
# Configura el método de autenticación Kubernetes en Vault para que Jenkins
# lea el secreto del microservicio sin ningún token de Vault hardcodeado.
#
# Se corre UNA SOLA VEZ, después de que Vault ya esté desplegado, inicializado
# y unsealed (no antes: no hay Vault contra el cual escribir todavía). No se
# ejecutó en esta sesión por lo mismo.
#
# Requiere: `vault login` ya hecho (token de admin, normalmente el root token
# de la inicialización) contra VAULT_ADDR, y kubectl apuntando al clúster
# deployment (kubectl config current-context).
set -euo pipefail

: "${VAULT_ADDR:?export VAULT_ADDR primero, ej. http://localhost:8200 si se hizo port-forward al Service de Vault}"

echo "==> Habilitando el secrets engine KV v2 en secret/ (si no existe)"
vault secrets list -format=json | grep -q '"secret/"' || vault secrets enable -path=secret kv-v2

echo "==> Cargando el secreto de ejemplo que consumirá el microservicio"
echo "    (cambiar el valor antes de usarlo fuera de este laboratorio)"
vault kv put secret/microservice value="cambia-este-valor-antes-de-usarlo-de-verdad"

echo "==> Habilitando el método de autenticación Kubernetes en un mount propio"
echo "    (path explícito porque el clúster development usa OTRO mount contra"
echo "    este mismo Vault, ver k8s/development/vault/vault-k8s-auth-setup.sh)"
vault auth list -format=json | grep -q '"kubernetes-jenkins/"' || vault auth enable -path=kubernetes-jenkins kubernetes

echo "==> Configurando el auth method contra la API del clúster deployment"
KUBE_HOST=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
KUBE_CA=$(kubectl config view --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)

vault write auth/kubernetes-jenkins/config \
  kubernetes_host="${KUBE_HOST}" \
  kubernetes_ca_cert="${KUBE_CA}"

echo "==> Escribiendo la política de mínimo privilegio (vault-policy.hcl)"
vault policy write jenkins-microservice ./vault-policy.hcl

echo "==> Creando el role que liga la ServiceAccount de Jenkins a esa política"
# bound_service_account_names=jenkins-ecr-push (no una ServiceAccount aparte
# solo para Vault): el pod que corre "withVault(...)" en el Jenkinsfile es el
# mismo que necesita IRSA para hacer push a ECR, y un pod solo puede tener una
# serviceAccountName -- Vault solo usa el JWT para TokenReview, no le hace
# falta ningun permiso de RBAC de k8s, asi que reutilizar esta identidad no
# amplia el acceso de nadie. (Confirmado en vivo: con una ServiceAccount
# distinta el login fallaba con "service account name not authorized".)
vault write auth/kubernetes-jenkins/role/jenkins-microservice \
  bound_service_account_names=jenkins-ecr-push \
  bound_service_account_namespaces=jenkins \
  policies=jenkins-microservice \
  ttl=15m

cat <<'EOF'

Listo. Jenkins y Vault corren en el mismo clúster (deployment), así que desde
el Jenkinsfile el plugin de Vault se conecta por DNS interno del clúster:

  vaultUrl: http://vault.vault.svc.cluster.local:8200
  vaultCredentialId -> Kubernetes auth, mount "kubernetes-jenkins", role "jenkins-microservice"

EOF
