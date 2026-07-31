package hn.jelsync.labeks.microservice.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(MicroserviceController.class)
@TestPropertySource(properties = {
        "app.vault.secret-env-var=VAULT_SECRET",
        "app.config.message=config-de-prueba",
        "VAULT_SECRET=valor-de-prueba"
})
class MicroserviceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void envSecretDevuelveElValorInyectado() throws Exception {
        mockMvc.perform(get("/api/env-secret"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.envVarName").value("VAULT_SECRET"))
                .andExpect(jsonPath("$.value").value("valor-de-prueba"));
    }

    @Test
    void configPropertyDevuelveLaPropiedadConfigurada() throws Exception {
        mockMvc.perform(get("/api/config-property"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.property").value("app.config.message"))
                .andExpect(jsonPath("$.value").value("config-de-prueba"));
    }
}
