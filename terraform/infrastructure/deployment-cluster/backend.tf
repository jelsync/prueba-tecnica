# Backend local mientras se confirma la cuenta/región definitiva de AWS y el rol
# de Azure DevOps en el flujo. TODO: migrar a backend "s3" con locking nativo
# (o DynamoDB) una vez esté decidido; por ahora no hay ningún "apply" real
# corrido contra este backend.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
