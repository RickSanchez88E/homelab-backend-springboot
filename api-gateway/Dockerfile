FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/api-gateway.jar api-gateway.jar

EXPOSE 9191

ENTRYPOINT ["java", "-jar", "api-gateway.jar"]