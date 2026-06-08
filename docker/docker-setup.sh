#!/bin/bash

# Get directory for this script
RUNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/../common/env-config.sh

if [ ! -f "$DOCKERKEYS/openldap/ldap.key" ] || [ ! -f "$DOCKERKEYS/openldap/ldap.crt" ] || [ ! -f "$DOCKERKEYS/openldap/ca.crt" ] || [ ! -f "$DOCKERKEYS/openldap/dhparam.pem" ] || [ ! -f "$DOCKERKEYS/postgresql/server.pem" ] || [ ! -f "$DOCKERKEYS/isvaop/personal/isvaop.key" ] || [ ! -f "$DOCKERKEYS/isvaop/signer/isvaop.pem" ]
then
  echo "Key files not found.  Restore or create keys before running this script."
  exit 1
fi

docker network create ivia

docker volume create iviaconfig
docker volume create libldap
docker volume create libsecauthority
docker volume create ldapslapd
docker volume create pgdata

docker run -t -d --restart always -v pgdata:/var/lib/postgresql/data -v ${DOCKERKEYS}/postgresql:/var/local -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=Passw0rd -e POSTGRES_DB=ivia -e POSTGRES_SSL_KEYDB=/var/local/server.pem --hostname postgresql --name postgresql --network ivia icr.io/ivia/ivia-postgresql:${DB_VERSION}

docker run -t -d --restart always -v libldap:/var/lib/ldap -v ldapslapd:/etc/ldap/slapd.d -v libsecauthority:/var/lib/ldap.secAuthority -v ${DOCKERKEYS}/openldap:/container/service/slapd/assets/certs --hostname openldap --name openldap -e LDAP_DOMAIN=ibm.com -e LDAP_ADMIN_PASSWORD=Passw0rd -e LDAP_CONFIG_PASSWORD=Passw0rd -p ${MY_LMI_IP}:1636:636 --network ivia icr.io/isva/verify-access-openldap:${LDAP_VERSION} --copy-service

docker run -t -d --restart always -v iviaconfig:/var/shared --hostname iviaconfig --name iviaconfig -e CONTAINER_TIMEZONE=Europe/London -e ADMIN_PWD=Passw0rd -p ${MY_LMI_IP}:443:9443 --network ivia icr.io/ivia/ivia-config:${ISVA_VERSION}

docker run -t -d --restart always -v iviaconfig:/var/shared --hostname iviawrprp1 --name iviawrprp1 -e CONTAINER_TIMEZONE=Europe/London -p ${MY_WEB1_IP}:443:9443 -e INSTANCE=rp1 --network ivia icr.io/ivia/ivia-wrp:${ISVA_VERSION}

docker run -t -d --restart always -v iviaconfig:/var/shared --hostname iviaruntime --name iviaruntime -e CONTAINER_TIMEZONE=Europe/London --network ivia icr.io/ivia/ivia-runtime:${ISVA_VERSION}

docker run -t -d --restart always -v iviaconfig:/var/shared --hostname iviadsc --name iviadsc -e CONTAINER_TIMEZONE=Europe/London -e INSTANCE=1 --network ivia icr.io/ivia/ivia-dsc:${ISVA_VERSION}

docker run -t -d --restart always -v ${IVIAOPCONFIG}:/var/isvaop/config --hostname isvaop --name isvaop -e CONTAINER_TIMEZONE=Europe/London -e INSTANCE=1 --network ivia ${CONTAINER_BASE}-oidc-provider:${IVIAOP_VERSION}
