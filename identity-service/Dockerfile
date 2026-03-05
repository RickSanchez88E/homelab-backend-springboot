FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/identity-service.jar identity-service.jar

EXPOSE 9898

ENTRYPOINT ["java", "-jar", "identity-service.jar"]