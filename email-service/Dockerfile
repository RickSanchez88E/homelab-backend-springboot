FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/email-service.jar email-service.jar

EXPOSE 8086

ENTRYPOINT ["java", "-jar", "email-service.jar"]