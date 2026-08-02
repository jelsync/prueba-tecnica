# ---- Build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---- Runtime ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# UID numerico explicito (no solo el nombre "app"): con runAsNonRoot en el
# Deployment, Kubernetes no puede verificar en admision que un USER no
# numerico sea no-root y rechaza el contenedor ("has non-numeric user (app),
# cannot verify user is non-root"). El mismo UID se fija en el securityContext
# del Deployment para que ambos coincidan.
RUN addgroup -S app && adduser -S -u 10001 -G app app
COPY --from=build /app/target/microservice.jar ./app.jar
USER 10001

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
