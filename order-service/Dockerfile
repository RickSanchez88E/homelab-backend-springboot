FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/order-service.jar order-service.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "order-service.jar"]