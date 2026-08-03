FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S app && adduser -S -u 10001 -G app app
COPY --from=build /app/target/microservice.jar ./app.jar
USER 10001

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
