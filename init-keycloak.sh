#!/usr/bin/env bash

set -e

if [[ -z $(docker ps --filter "name=keycloak" -q) ]]; then
  echo "[ERROR] You must run (docker compose up -d) before initializing Keycloak"
  exit 1
fi

KEYCLOAK_HOST_PORT=${1:-"localhost:8080"}
KEYCLOAK_BASE_URL="http://$KEYCLOAK_HOST_PORT"

echo
echo "KEYCLOAK_BASE_URL: $KEYCLOAK_BASE_URL"
echo

echo "Getting admin access token"
echo "=========================="

ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_BASE_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [[ -z "$ADMIN_TOKEN" || "$ADMIN_TOKEN" == "null" ]]; then
  echo "[ERROR] Failed to get admin token"
  exit 1
fi

echo

echo "Creating realm"
echo "=============="

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"realm": "company-services", "enabled": true}' || true

echo "Disabling required action Verify Profile"
echo "----------------------------------------"

VERIFY_PROFILE=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.enabled = false')

curl -si -X PUT "$KEYCLOAK_BASE_URL/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$VERIFY_PROFILE"

echo "Creating client"
echo "==============="

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"clientId": "simple-service", "directAccessGrantsEnabled": true, "redirectUris": ["http://localhost:9080/*"]}' || true

CLIENT_UUID=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/clients?clientId=simple-service" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "CLIENT_UUID=$CLIENT_UUID"
echo

echo "Getting client secret"
echo "====================="

SIMPLE_SERVICE_CLIENT_SECRET=$(curl -s -X GET "$KEYCLOAK_BASE_URL/admin/realms/company-services/clients/$CLIENT_UUID/client-secret" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.value')

echo "SIMPLE_SERVICE_CLIENT_SECRET=$SIMPLE_SERVICE_CLIENT_SECRET"
echo

echo "Creating client role"
echo "===================="

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/clients/$CLIENT_UUID/roles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "USER"}' || true

ROLE_ID=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/clients/$CLIENT_UUID/roles/USER" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')

echo "ROLE_ID=$ROLE_ID"
echo

echo "Configuring LDAP"
echo "==============="

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/components" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '@ldap/ldap-config.json' || true

LDAP_COMPONENT_NAME=$(jq -r '.name' ldap/ldap-config.json)
LDAP_ID=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/components?type=org.keycloak.storage.UserStorageProvider&name=$LDAP_COMPONENT_NAME" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "LDAP_ID=$LDAP_ID"
echo

echo "Syncing LDAP users"
echo "==================="

curl -i -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/user-storage/$LDAP_ID/sync?action=triggerFullSync" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

echo
echo
echo "Getting bgates id"
echo "================="

BGATES_ID=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/users?username=bgates&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "BGATES_ID=$BGATES_ID"
echo

echo "Assigning USER role to bgates"
echo "============================="

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/users/$BGATES_ID/role-mappings/clients/$CLIENT_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\":\"$ROLE_ID\",\"name\":\"USER\"}]"

echo "Getting sjobs id"
echo "==============="

SJOBS_ID=$(curl -s "$KEYCLOAK_BASE_URL/admin/realms/company-services/users?username=sjobs&exact=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

echo "SJOBS_ID=$SJOBS_ID"
echo

echo "Assigning USER role to sjobs"
echo "============================"

curl -si -X POST "$KEYCLOAK_BASE_URL/admin/realms/company-services/users/$SJOBS_ID/role-mappings/clients/$CLIENT_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\":\"$ROLE_ID\",\"name\":\"USER\"}]"

echo "Getting bgates access token"
echo "==========================="

curl -s -X POST "$KEYCLOAK_BASE_URL/realms/company-services/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=bgates" \
  -d "password=123" \
  -d "grant_type=password" \
  -d "client_secret=$SIMPLE_SERVICE_CLIENT_SECRET" \
  -d "client_id=simple-service" | jq -r .access_token
echo

echo "Getting sjobs access token"
echo "=========================="

curl -s -X POST "$KEYCLOAK_BASE_URL/realms/company-services/protocol/openid-connect/token" \
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
