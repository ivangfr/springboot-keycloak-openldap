#!/usr/bin/env bash

if [ "$1" = "native" ];
then
  ./mvnw clean spring-boot:build-image --projects simple-service -DskipTests
else
  ./mvnw clean compile jib:dockerBuild --projects simple-service
fi
