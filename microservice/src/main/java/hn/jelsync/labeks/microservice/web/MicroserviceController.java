package hn.jelsync.labeks.microservice.web;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MicroserviceController {

    private static final String NOT_INJECTED_PLACEHOLDER = "(no inyectada)";

    private final Environment environment;

    @Value("${app.vault.secret-env-var}")
    private String vaultSecretEnvVarName;

    @Value("${app.config.message}")
    private String configMessage;

    public MicroserviceController(Environment environment) {
        this.environment = environment;
    }

    @GetMapping("/api/env-secret")
    public Map<String, String> envSecret() {
        String value = environment.getProperty(vaultSecretEnvVarName);
        return Map.of(
                "envVarName", vaultSecretEnvVarName,
                "value", value != null ? value : NOT_INJECTED_PLACEHOLDER);
    }

    @GetMapping("/api/config-property")
    public Map<String, String> configProperty() {
        return Map.of(
                "property", "app.config.message",
                "value", configMessage);
    }
}
