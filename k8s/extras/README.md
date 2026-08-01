# Extras (puntos adicionales, no obligatorios)

Ambos se probaron de verdad contra un clúster [kind](https://kind.sigs.k8s.io/) local
(desechable, se creó y se borró en esta misma sesión) — no solo se escribieron.

## CronJob de auditoría de eventos del kubelet

`kubelet-events-cronjob.yaml` — cada 10 minutos, `kubectl get events --all-namespaces
--field-selector source=kubelet` en un namespace propio (`platform-audit`), con RBAC de solo
lectura sobre `events`. Si existe un Secret `slack-webhook` (no incluido, opcional) con una key
`url`, además notifica a Slack/Discord cuando hay eventos; sin el Secret, el log del Job ya sirve
como auditoría (`kubectl logs`).

Aplicable a cualquiera de los dos clústeres — no depende de nada específico de `development` ni
`deployment`.

Probado disparando un Job manual (`kubectl create job --from=cronjob/...`): encontró 52 eventos
reales del kubelet en el clúster de prueba y los imprimió como JSON válido. En el camino se
encontró que la imagen `bitnami/kubectl:1.31` ya no existe (Bitnami reorganizó sus tags) —
reemplazada por `alpine/k8s:1.31.0`, verificada con `docker pull` antes de usarla.

## CRD `MicroserviceConfig`

```
microserviceconfig/
├── crd.yaml                    # logLevel / restartPolicy (enum) + healthCheckPath (patrón)
├── sample.yaml                 # CR de ejemplo para el microservicio del laboratorio
└── controller/                 # controlador opcional en Python
    ├── controller.py
    ├── requirements.txt
    ├── Dockerfile
    └── deployment.yaml
```

El controlador (opcional, per el enunciado) solo *procesa* el CRD — no reconcilia ni muta otro
recurso, porque eso no es lo que pide el laboratorio. Al ver un `MicroserviceConfig` nuevo o
modificado, lo registra y actualiza su `.status` (`observedGeneration`, `lastProcessedAt`).

**Bug real encontrado y corregido probando esto contra kind**: el propio `patch` al `.status`
dispara otro evento `MODIFIED`, así que sin cuidado el controlador se reprocesa a sí mismo en
loop infinito. Se corrigió comparando `metadata.generation` contra `status.observedGeneration`
antes de procesar — `generation` solo cambia con el `spec`, nunca con el subrecurso `status`. Ya
corregido: no reprocesa al arrancar (si ambos coinciden) y procesa exactamente una vez ante un
cambio real de `spec` (confirmado: `logLevel: info → debug` disparó un único log y un único
patch).

También se confirmó que la validación OpenAPI del CRD funciona de verdad: `kubectl patch` con
`logLevel: invalido` lo rechaza el API server, no hace falta que el controlador lo valide.

### Probarlo

```bash
kind create cluster --name labeks-extras
kubectl apply -f microserviceconfig/crd.yaml
kubectl create namespace development
kubectl apply -f microserviceconfig/sample.yaml

cd microserviceconfig/controller
python -m venv venv && ./venv/*/pip install -r requirements.txt
./venv/*/python controller.py   # escucha; en otra terminal, editar el CR y ver el log
```

Para correrlo dentro del clúster en vez de local: build+push la imagen de `controller/Dockerfile`
y `kubectl apply -f controller/deployment.yaml` con esa imagen.
