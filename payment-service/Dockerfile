FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/payment-service.jar payment-service.jar

EXPOSE 8085

ENTRYPOINT ["java", "-jar", "payment-service.jar"]