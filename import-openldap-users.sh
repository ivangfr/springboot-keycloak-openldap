#!/usr/bin/env bash

LDAP_HOST=${1:-localhost}

ldapadd -x -D "cn=admin,dc=mycompany,dc=com" -w admin -H ldap://$LDAP_HOST -f ldap/ldap-mycompany-com.ldif