import datetime
import logging

from kubernetes import client, config, watch

GROUP = "labeks.jelsync.hn"
VERSION = "v1"
PLURAL = "microserviceconfigs"

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("microserviceconfig-controller")


def load_kube_config():
    try:
        config.load_incluster_config()
    except config.ConfigException:
        config.load_kube_config()


def process(api, obj):
    metadata = obj["metadata"]
    spec = obj.get("spec", {})
    status = obj.get("status") or {}
    generation = metadata.get("generation", 0)
    name = metadata["name"]
    namespace = metadata["namespace"]

    if status.get("observedGeneration") == generation:
        return

    log.info(
        "MicroserviceConfig %s/%s -> logLevel=%s restartPolicy=%s healthCheckPath=%s",
        namespace, name,
        spec.get("logLevel"), spec.get("restartPolicy"), spec.get("healthCheckPath"),
    )

    status_patch = {
        "status": {
            "observedGeneration": metadata.get("generation", 0),
            "lastProcessedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }
    }
    api.patch_namespaced_custom_object_status(
        GROUP, VERSION, namespace, PLURAL, name, status_patch,
    )


def main():
    load_kube_config()
    api = client.CustomObjectsApi()
    w = watch.Watch()

    log.info("Escuchando MicroserviceConfig en todos los namespaces...")
    for event in w.stream(api.list_cluster_custom_object, GROUP, VERSION, PLURAL):
        obj = event["object"]
        if event["type"] in ("ADDED", "MODIFIED"):
            try:
                process(api, obj)
            except Exception:
                log.exception(
                    "error procesando %s/%s",
                    obj["metadata"].get("namespace"), obj["metadata"].get("name"),
                )


if __name__ == "__main__":
    main()
