# Política de mínimo privilegio para Jenkins: solo lectura del secreto que
# el pipeline inyecta como variable de entorno antes del build. Nada de
# escritura, nada de otros paths, nada de acceso a sys/ ni a otras políticas.
path "secret/data/microservice" {
  capabilities = ["read"]
}
