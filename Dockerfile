FROM openjdk:8-jre-alpine

LABEL maintainer="ivangfr@yahoo.com.br"

ARG JAR_FILE
COPY ${JAR_FILE} /app.jar

CMD ["java", "-jar", "/app.jar"]

EXPOSE 8080