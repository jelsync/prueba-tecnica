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
        "app.vault.secret-env-var=UNA_VARIABLE_QUE_NO_EXISTE_EN_EL_ENTORNO",
        "app.config.message=otra-config"
})
class MicroserviceControllerMissingSecretTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void envSecretDevuelvePlaceholderCuandoNoFueInyectada() throws Exception {
        mockMvc.perform(get("/api/env-secret"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.value").value("(no inyectada)"));
    }
}
