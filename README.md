# springboot-keycloak-openldap

The goal of this project is to create a simple [Spring Boot](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/) REST API, called `simple-service`, and secure it with [`Keycloak`](https://www.keycloak.org). Furthermore, the API users will be loaded into `Keycloak` from [`OpenLDAP`](https://www.openldap.org) server.

> **Note 1:** In [`springboot-react-keycloak`](https://github.com/ivangfr/springboot-react-keycloak) repository, we have implemented a `movies-app` using `Keycloak` (with `PKCE`). This application consists of two services: the backend that was implemented using `Spring Boot` and the frontend implemented with `ReactJS`.

> **Note 2:** In [`docker-swarm-environment`](https://github.com/ivangfr/docker-swarm-environment) repository, it's shown how to deploy this project into a cluster of Docker Engines in swarm mode. Besides, we will be running a Keycloak cluster with more than one instance.

## Application

- ### simple-service

  `Spring Boot` Web Java application that exposes two endpoints:
  
  - `/api/public`: endpoint that can be access by anyone, it is not secured;
  - `/api/private`: endpoint that can just be accessed by users that provide a `JWT` token issued by `Keycloak` and the token must contain the role `USER`.

## Prerequisites

- [`Java 11+`](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
- [`Docker`](https://www.docker.com/)
- [`Docker-Compose`](https://docs.docker.com/compose/install/)
- [`jq`](https://stedolan.github.io/jq)

## Start Environment

- Open a terminal and inside `springboot-keycloak-openldap` root folder run
  ```
  docker-compose up -d
  ```

- Wait until `MySQL` and `Keycloak` containers are `Up (healthy)`. In order to check it run
  ```
  docker-compose ps
  ```

## Import OpenLDAP Users

The `LDIF` file that we will use, `springboot-keycloak-openldap/ldap/ldap-mycompany-com.ldif`, contains a pre-defined structure for `mycompany.com`. Basically, it has 2 groups (`developers` and `admin`) and 4 users (`Bill Gates`, `Steve Jobs`, `Mark Cuban` and `Ivan Franchin`). Besides, it's defined that `Bill Gates`, `Steve Jobs` and `Mark Cuban` belong to `developers` group and `Ivan Franchin` belongs to `admin` group.
```
Bill Gates > username: bgates, password: 123
Steve Jobs > username: sjobs, password: 123
Mark Cuban > username: mcuban, password: 123
Ivan Franchin > username: ifranchin, password: 123
```

There are two ways to import those users: running a script or using `phpldapadmin` website

### Running a script

In a terminal and inside `springboot-keycloak-openldap` root folder run
```
./import-openldap-users.sh
```

### Using phpldapadmin website

- Access https://localhost:6443

- Login with the credentials
  ```
  Login DN: cn=admin,dc=mycompany,dc=com
  Password: admin
  ```

- Import the file `springboot-keycloak-openldap/ldap/ldap-mycompany-com.ldif`

- You should see a tree like the one shown in the picture below

  ![phpldapadmin](images/phpldapadmin.png)

## Configure Keycloak

There are two ways: running a script or using `Keycloak` website

### Running a script

- In a terminal, make sure you are inside `springboot-keycloak-openldap` root folder

- Run the script below to configure `Keycloak` for `simple-service` application
  ```
  ./init-keycloak.sh
  ```

  It creates `company-services` realm, `simple-service` client, `USER` client role, `ldap` federation and the users `bgates` and `sjobs` with the role `USER` assigned.

- Copy `SIMPLE_SERVICE_CLIENT_SECRET` value that is shown at the end of the script. It will be needed whenever we call `Keycloak` to get a token to access `simple-service`

### Using Keycloak website

![keycloak](images/keycloak.png)

#### Login

- Access http://localhost:8080/auth/admin/

- Login with the credentials
  ```
  Username: admin
  Password: admin
  ```

#### Create a new Realm

- Go to top-left corner and hover the mouse over `Master` realm. Click the `Add realm` blue button that will appear
- For the `Name` field set `company-services` and click `Create` button

#### Create a new Client

- On the left menu, click `Clients` 
- Click `Create` button
- Set `simple-service` for `Client ID` and click `Save` button
- In `Settings` tab
  - Set `confidential` for `Access Type`
  - Set `http://localhost:9080` for `Valid Redirect URIs`
- Click `Save` button
- In `Credentials` tab you can find the secret `Keycloak` generated for `simple-service`
- In `Roles` tab
  - Click `Add Role` button
  - Set `USER` to `Role Name` and click `Save` button

#### LDAP Integration

- On the left menu, click `User Federation`
- Select `ldap`
- Select `Other` for `Vendor`
- Set `ldap://ldap-host` for `Connection URL`
- Click `Test connection` button, to check if the connection is OK
- Set `ou=users,dc=mycompany,dc=com` for `Users DN` 
- Set `(gidnumber=500)` for `Custom User LDAP Filter` (filter just developers)
- Set `cn=admin,dc=mycompany,dc=com` for `Bind DN`
- Set `admin` for `Bind Credential`
- Click `Test authentication` button, to check if the authentication is OK
- Click `Save` button
- Click `Synchronize all users` button

#### Configure users imported

- On the left menu, click `Users`
- Click `View all users` button. 3 users should be shown
- Edit user `bgates` by clicking on its `ID` or `Edit` button
- In `Role Mappings` tab
  - Select `simple-service` in `Client Roles` combo-box
  - Select `USER` role present in `Available Roles` and click `Add selected`
  - `bgates` has now `USER` role as one of his `Assigned Roles`
- Do the same for the user `sjobs`
- Let's leave `mcuban` without `USER` role

## Run simple-service using Maven

- Open a new terminal and make sure you are in `springboot-keycloak-openldap` root folder

- Start the application by running the following command
  ```
  ./mvnw clean spring-boot:run --projects simple-service -Dspring-boot.run.jvmArguments="-Dserver.port=9080"
  ```

## Test using curl

1. Open a new terminal

1. Call the endpoint `GET /api/public`
   ```
   curl -i http://localhost:9080/api/public
   ```
   
   It should return
   ```
   HTTP/1.1 200
   It is public.
   ```
   
1. Try to call the endpoint `GET /api/private` without authentication
   ``` 
   curl -i http://localhost:9080/api/private
   ```
   
   It should return
   ```
   HTTP/1.1 302
   ```
   > Here, the application is trying to redirect the request to an authentication link

1. Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `simple-service` at [Configure Keycloak](#configure-keycloak) step
   ```
   SIMPLE_SERVICE_CLIENT_SECRET=...
   ```

1. Run the command below to get an access token for `bgates` user
   ```
   BGATES_ACCESS_TOKEN=$(curl -s -X POST \
     "http://localhost:8080/auth/realms/company-services/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=bgates" \
     -d "password=123" \
     -d "grant_type=password" \
     -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
     -d "client_id=simple-service" | jq -r .access_token)
   ```

1. Call the endpoint `GET /api/private`
   ```
   curl -i -H "Authorization: Bearer $BGATES_ACCESS_TOKEN" http://localhost:9080/api/private
   ```
   
   It should return
   ```
   HTTP/1.1 200
   bgates, it is private.
   ```

1. Run the command below to get an access token for `mcuban` user
   ```
   MCUBAN_ACCESS_TOKEN=$(curl -s -X POST \
     "http://localhost:8080/auth/realms/company-services/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=mcuban" \
     -d "password=123" \
     -d "grant_type=password" \
     -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
     -d "client_id=simple-service" | jq -r .access_token)
   ```

1. Try to call the endpoint `GET /api/private`
   ```
   curl -i -H "Authorization: Bearer $MCUBAN_ACCESS_TOKEN" http://localhost:9080/api/private
   ```
   As `mcuban` does not have the `USER` role, he cannot access this endpoint.
   
   The endpoint return should be
   ```
   HTTP/1.1 403
   {
     "timestamp":"2018-12-26T13:14:10.493+0000",
     "status":403,
     "error":"Forbidden",
     "message":"Forbidden",
     "path":"/api/private"
   }
   ```

1. Go to `Keycloak` and add the role `USER` to the `mcuban`

1. Run the command mentioned in `step 7)` again to get a new access token for `mcuban` user

1. Call again the endpoint `GET /api/private` using the `curl` command presented in `step 8`

   It should return
   ```
   HTTP/1.1 200
   mcuban, it is private.
   ```

1. The access token default expiration period is `5 minutes`. So, wait for this time and, using the same access token, try to call the private endpoint.

   It should return
   ```
   HTTP/1.1 401
   WWW-Authenticate: Bearer realm="company-services", error="invalid_token", error_description="Token is not active"
   ```

## Test using Swagger

1. Access http://localhost:9080/swagger-ui.html

   ![simple-service-swagger](images/simple-service-swagger.png)

1. Click `GET /api/public` to open it. Then, click `Try it out` button and, finally, click `Execute` button

   It should return
   ```
   Code: 200
   Response Body: It is public.
   ```

1. Now click `GET /api/private` secured endpoint. Let's try it without authentication. Then, click `Try it out` button and, finally, click `Execute` button
  
   It should return
   ```
   Failed to fetch
   ```

1. In order to access the private endpoint, you need an access token. So, open a terminal

1. Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `simple-service` at [Configure Keycloak](#configure-keycloak) step
   ```
   SIMPLE_SERVICE_CLIENT_SECRET=...
   ```
  
1. Run the following commands
   ```
   BGATES_ACCESS_TOKEN=$(curl -s -X POST \
     "http://localhost:8080/auth/realms/company-services/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=bgates" \
     -d "password=123" \
     -d "grant_type=password" \
     -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
     -d "client_id=simple-service" | jq -r .access_token)
     
   echo $BGATES_ACCESS_TOKEN
   ```

1. Copy the token generated and go back to `Swagger`

1. Click `Authorize` button and paste the access token in the `Value` field. Then, click `Authorize` button and, to finalize, click `Close`

1. Go to `GET /api/private` and call this endpoint again, now with authentication

   It should return
   ```
   Code: 200
   Response Body: bgates, it is private.
   ```

## Using client_id and client_secret to get access token

You can get an access token to `simple-service` using `client_id` and `client_secret`

### Configuration

- Access http://localhost:8080/auth/admin/
- Select `company-services` realm (if it is not already selected)
- On the left menu, click `Clients`
- Select `simple-service` client
- In `Settings` tab
  - Turn `ON` the field `Service Accounts Enabled`
  - Click `Save` button
- In `Service Account Roles`tab
  - Select `simple-service` in `Client Roles` combo-box
  - Select `USER` role present in `Available Roles` and click `Add selected`

### Test

1. Open a terminal

1. Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `simple-service` at [Configure Keycloak](#configure-keycloak) step
   ```
   SIMPLE_SERVICE_CLIENT_SECRET=...
   ```
  
1. Run the following command
   ```
   CLIENT_ACCESS_TOKEN=$(curl -s -X POST \
     "http://localhost:8080/auth/realms/company-services/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials" \
     -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
     -d "client_id=simple-service" | jq -r .access_token)
   ```
  
1. Try to call the endpoint `GET /api/private`
   ```
   curl -i http://localhost:9080/api/private -H "authorization: Bearer $CLIENT_ACCESS_TOKEN"
   ```
  
   It should return
   ```
   HTTP/1.1 200
   service-account-simple-service, it is private.
   ```

## Running simple-service as a Docker container

- Build Docker Image
  - JVM
    ```
    ./docker-build.sh
    ```
  - Native (it's not working yet, see [Issues](#issues))
    ```
    ./docker-build.sh native
    ```
  
- Environment Variables

  | Environment Variable | Description                                                 |
  | -------------------- | ----------------------------------------------------------- |
  | `KEYCLOAK_HOST`      | Specify host of the `Keycloak` to use (default `localhost`) |
  | `KEYCLOAK_PORT`      | Specify port of the `Keycloak` to use (default `8080`)      |

- Run `simple-service` docker container, joining it to docker-compose network
  ```
  docker run -d --rm -p 9080:8080 \
    --name simple-service \
    --network=springboot-keycloak-openldap_default \
    --env KEYCLOAK_HOST=keycloak \
    docker.mycompany.com/simple-service:1.0.0
  ```

- Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `simple-service` at [Configure Keycloak](#configure-keycloak) step
  ```
  SIMPLE_SERVICE_CLIENT_SECRET=...
  ```  

- Run the commands below to get an access token for `bgates` user
  ```
  BGATES_TOKEN=$(
      docker exec -t -e CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET keycloak bash -c '
        curl -s -X POST \
        http://keycloak:8080/auth/realms/company-services/protocol/openid-connect/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=bgates" \
        -d "password=123" \
        -d "grant_type=password" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "client_id=simple-service"')
  
  BGATES_ACCESS_TOKEN=$(echo $BGATES_TOKEN | jq -r .access_token)
  ```

- Call the endpoint `GET /api/private`
  ```
  curl -i -H "Authorization: Bearer $BGATES_ACCESS_TOKEN" http://localhost:9080/api/private
  ```

## Shutdown

- Stop `simple-service` application
  - If it was started with `Maven`, go to the terminal where it is running and press `Ctrl+C`
  - If it was started as a Docker container, run in a terminal the command below
    ```
    docker stop simple-service
    ```

- To stop and remove docker-compose containers, networks and volumes, run the command below in `springboot-keycloak-openldap` root folder
  ```
  docker-compose down -v
  ```

## Useful Links/Commands

- **jwt.io**

  With [jwt.io](https://jwt.io) you can inform the JWT token received from `Keycloak` and the online tool decodes the token, showing its header and payload.

- **ldapsearch**

  It can be used to check the users imported into `OpenLDAP`
  ```
  ldapsearch -x -D "cn=admin,dc=mycompany,dc=com" \
    -w admin -H ldap://localhost:389 \
    -b "ou=users,dc=mycompany,dc=com" \
    -s sub "(uid=*)"
  ```

## Generating missing configuration for native image

> **IMPORTANT**: you must have `GraalVM` and its tool `native-image` installed.
> **TIP**: For more information see [Spring Native documentation](https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/#_missing_configuration)

- Run the following steps in a terminal and inside `springboot-keycloak-openldap` root folder
  ```
  mkdir -p simple-service/src/main/resources/META-INF/native-image
  
  ./mvnw clean package --projects simple-service
  
  cd simple-service
  
  java -jar -agentlib:native-image-agent=config-output-dir=src/main/resources/META-INF/native-image -Dserver.port=9080 target/simple-service-1.0.0.jar
  ```

- It should generate `JSON` files in `src/main/resources/META-INF/native-image` like `jni-config.json`, `proxy-config.json` etc.

## Issues

- If the missing configuration for native image is generated using the `native-image-agent`, it's throwing the following error while building the Docker native image. It's fixed in this [issue #2951](https://github.com/oracle/graal/issues/2951). Waiting for `GraalVM 21.1` milestone be completed/released
  ```
  ...
  [INFO]     [creator]     Error: type is not available in this platform: org.graalvm.compiler.hotspot.management.AggregatedMemoryPoolBean
  [INFO]     [creator]     Error: Use -H:+ReportExceptionStackTraces to print stacktrace of underlying exception
  [INFO]     [creator]     Error: Image build request failed with exit status 1
  [INFO]     [creator]     unable to invoke layer creator
  [INFO]     [creator]     unable to contribute native-image layer
  [INFO]     [creator]     error running build
  [INFO]     [creator]     exit status 1
  [INFO]     [creator]     ERROR: failed to build: exit status 1
  ...
  ```

- If the missing configuration is NOT generated, the following exception is thrown at Docker native container runtime
  ```
    .   ____          _            __ _ _
   /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
  ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
   \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
    '  |____| .__|_| |_|_| |_\__, | / / / /
   =========|_|==============|___/=/_/_/_/
   :: Spring Boot ::                (v2.4.3)
  
  2021-03-15 13:42:45.383  INFO 1 --- [           main] c.m.s.SimpleServiceApplication           : Starting SimpleServiceApplication using Java 11.0.10 on ad7c5792573c with PID 1 (/workspace/com.mycompany.simpleservice.SimpleServiceApplication started by cnb in /workspace)
  2021-03-15 13:42:45.384  INFO 1 --- [           main] c.m.s.SimpleServiceApplication           : No active profile set, falling back to default profiles: default
  2021-03-15 13:42:45.473 ERROR 1 --- [           main] o.s.boot.SpringApplication               : Application run failed
  
  java.lang.IllegalStateException: Error processing condition on org.springdoc.core.SpringDocConfiguration$SpringDocActuatorConfiguration.springdocBeanFactoryPostProcessor3
  	at org.springframework.boot.autoconfigure.condition.SpringBootCondition.matches(SpringBootCondition.java:60) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.context.annotation.ConditionEvaluator.shouldSkip(ConditionEvaluator.java:108) ~[na:na]
  	at org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader.loadBeanDefinitionsForBeanMethod(ConfigurationClassBeanDefinitionReader.java:193) ~[na:na]
  	at org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader.loadBeanDefinitionsForConfigurationClass(ConfigurationClassBeanDefinitionReader.java:153) ~[na:na]
  	at org.springframework.context.annotation.ConfigurationClassBeanDefinitionReader.loadBeanDefinitions(ConfigurationClassBeanDefinitionReader.java:129) ~[na:na]
  	at org.springframework.context.annotation.ConfigurationClassPostProcessor.processConfigBeanDefinitions(ConfigurationClassPostProcessor.java:342) ~[com.mycompany.simpleservice.SimpleServiceApplication:5.3.4]
  	at org.springframework.context.annotation.ConfigurationClassPostProcessor.postProcessBeanDefinitionRegistry(ConfigurationClassPostProcessor.java:246) ~[com.mycompany.simpleservice.SimpleServiceApplication:5.3.4]
  	at org.springframework.context.support.PostProcessorRegistrationDelegate.invokeBeanDefinitionRegistryPostProcessors(PostProcessorRegistrationDelegate.java:311) ~[na:na]
  	at org.springframework.context.support.PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(PostProcessorRegistrationDelegate.java:112) ~[na:na]
  	at org.springframework.context.support.AbstractApplicationContext.invokeBeanFactoryPostProcessors(AbstractApplicationContext.java:745) ~[na:na]
  	at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:563) ~[na:na]
  	at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.refresh(ServletWebServerApplicationContext.java:144) ~[na:na]
  	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:767) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:759) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:426) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.SpringApplication.run(SpringApplication.java:326) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1311) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.SpringApplication.run(SpringApplication.java:1300) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at com.mycompany.simpleservice.SimpleServiceApplication.main(SimpleServiceApplication.java:10) ~[com.mycompany.simpleservice.SimpleServiceApplication:na]
  Caused by: java.lang.IllegalStateException: java.io.FileNotFoundException: class path resource [org/springdoc/core/MultipleOpenApiSupportCondition.class] cannot be opened because it does not exist
  	at org.springframework.boot.autoconfigure.condition.AbstractNestedCondition$MemberConditions.getMetadata(AbstractNestedCondition.java:149) ~[na:na]
  	at org.springframework.boot.autoconfigure.condition.AbstractNestedCondition$MemberConditions.<init>(AbstractNestedCondition.java:113) ~[na:na]
  	at org.springframework.boot.autoconfigure.condition.AbstractNestedCondition.getMatchOutcome(AbstractNestedCondition.java:62) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	at org.springframework.boot.autoconfigure.condition.SpringBootCondition.matches(SpringBootCondition.java:47) ~[com.mycompany.simpleservice.SimpleServiceApplication:2.4.3]
  	... 18 common frames omitted
  Caused by: java.io.FileNotFoundException: class path resource [org/springdoc/core/MultipleOpenApiSupportCondition.class] cannot be opened because it does not exist
  	at org.springframework.core.io.ClassPathResource.getInputStream(ClassPathResource.java:180) ~[na:na]
  	at org.springframework.core.type.classreading.SimpleMetadataReader.getClassReader(SimpleMetadataReader.java:55) ~[na:na]
  	at org.springframework.core.type.classreading.SimpleMetadataReader.<init>(SimpleMetadataReader.java:49) ~[na:na]
  	at org.springframework.core.type.classreading.SimpleMetadataReaderFactory.getMetadataReader(SimpleMetadataReaderFactory.java:103) ~[na:na]
  	at org.springframework.core.type.classreading.SimpleMetadataReaderFactory.getMetadataReader(SimpleMetadataReaderFactory.java:81) ~[na:na]
  	at org.springframework.boot.autoconfigure.condition.AbstractNestedCondition$MemberConditions.getMetadata(AbstractNestedCondition.java:146) ~[na:na]
  	... 21 common frames omitted
  ```

## References

- https://www.keycloak.org/docs/latest/server_admin/
