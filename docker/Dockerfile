FROM openjdk:8-jdk-alpine

LABEL maintainer="ivangfr@yahoo.com.br"

RUN apk update && apk add ca-certificates wget curl jq && update-ca-certificates

ADD springboot-keycloak-openldap*.jar /springboot-keycloak-openldap.jar

CMD ["java", "-jar", "-Dkeycloak.auth-server-url=http://keycloak:8080/auth", "/springboot-keycloak-openldap.jar"]

EXPOSE 8080