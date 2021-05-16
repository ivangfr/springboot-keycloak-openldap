#!/usr/bin/env bash

KEYCLOAK_URL=${1:-localhost:8080}
echo
echo "KEYCLOAK_URL: $KEYCLOAK_URL"

echo
echo "Getting admin access token"
echo "=========================="

ADMIN_TOKEN=$(curl -s -X POST \
"http://$KEYCLOAK_URL/auth/realms/master/protocol/openid-connect/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=admin" \
-d 'password=admin' \
-d 'grant_type=password' \
-d 'client_id=admin-cli' | jq -r '.access_token')

echo "ADMIN_TOKEN=$ADMIN_TOKEN"

echo
echo "Creating realm"
echo "=============="

curl -i -X POST "http://$KEYCLOAK_URL/auth/admin/realms" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '{"realm": "company-services", "enabled": true}'

echo "Creating client"
echo "==============="

CLIENT_ID=$(curl -si -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/clients" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '{"clientId": "simple-service", "directAccessGrantsEnabled": true, "redirectUris": ["http://localhost:9080"]}' \
| grep -oE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

echo "CLIENT_ID=$CLIENT_ID"

echo
echo "Getting client secret"
echo "====================="

SIMPLE_SERVICE_CLIENT_SECRET=$(curl -s -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/clients/$CLIENT_ID/client-secret" \
-H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.value')

echo "SIMPLE_SERVICE_CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET"

echo
echo "Creating client role"
echo "===================="

curl -i -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/clients/$CLIENT_ID/roles" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '{"name": "USER"}'

ROLE_ID=$(curl -s "http://$KEYCLOAK_URL/auth/admin/realms/company-services/clients/$CLIENT_ID/roles" \
-H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "ROLE_ID=$ROLE_ID"

echo
echo "Configuring LDAP"
echo "================"

LDAP_ID=$(curl -si -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/components" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '@ldap/ldap-config.json' \
| grep -oE '[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}')

echo "LDAP_ID=$LDAP_ID"

echo
echo "Sync LDAP Users"
echo "==============="

curl -i -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/user-storage/$LDAP_ID/sync?action=triggerFullSync" \
-H "Authorization: Bearer $ADMIN_TOKEN"

echo
echo
echo "Get bgates id"
echo "============="

BGATES_ID=$(curl -s "http://$KEYCLOAK_URL/auth/admin/realms/company-services/users?username=bgates" \
-H "Authorization: Bearer $ADMIN_TOKEN"  | jq -r '.[0].id')

echo "BGATES_ID=$BGATES_ID"

echo
echo "Setting client role to bgates"
echo "============================="

curl -i -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/users/$BGATES_ID/role-mappings/clients/$CLIENT_ID" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '[{"id":"'"$ROLE_ID"'","name":"USER"}]'

echo "Get sjobs id"
echo "============"

SJOBS_ID=$(curl -s "http://$KEYCLOAK_URL/auth/admin/realms/company-services/users?username=sjobs" \
-H "Authorization: Bearer $ADMIN_TOKEN"  | jq -r '.[0].id')

echo "SJOBS_ID=$SJOBS_ID"

echo
echo "Setting client role to sjobs"
echo "============================"

curl -i -X POST "http://$KEYCLOAK_URL/auth/admin/realms/company-services/users/$SJOBS_ID/role-mappings/clients/$CLIENT_ID" \
-H "Authorization: Bearer $ADMIN_TOKEN" \
-H "Content-Type: application/json" \
-d '[{"id":"'"$ROLE_ID"'","name":"USER"}]'

echo "Getting bgates access token"
echo "==========================="

curl -s -X POST \
"http://$KEYCLOAK_URL/auth/realms/company-services/protocol/openid-connect/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=bgates" \
-d "password=123" \
-d "grant_type=password" \
-d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
-d "client_id=simple-service" | jq -r .access_token

echo
echo "Getting sjobs access token"
echo "=========================="

curl -s -X POST \
"http://$KEYCLOAK_URL/auth/realms/company-services/protocol/openid-connect/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=sjobs" \
-d "password=123" \
-d "grant_type=password" \
-d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
-d "client_id=simple-service" | jq -r .access_token

echo
echo "============================"
echo "SIMPLE_SERVICE_CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET"
echo "============================"
