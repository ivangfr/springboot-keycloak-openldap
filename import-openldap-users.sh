#!/usr/bin/env bash

ldapadd -x -D "cn=admin,dc=mycompany,dc=com" -w admin -H ldap:// -f ldap/ldap-mycompany-com.ldif