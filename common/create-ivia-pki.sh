#!/bin/bash
  
# Get directory for this script
RUNDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/env-config.sh

LDAP_CERT_DN="/CN=openldap/O=ibm/C=us"
POSTGRES_CERT_DN="/CN=postgresql/O=ibm/C=us"
ISVAOP_CERT_DN="/CN=isvaop.ibm.com/O=ibm/C=us"
ISVADC_CERT_DN="/CN=iviadc.ibm.com/O=ibm/C=us"
ISVAWRP_CERT_DN="/CN=isvawrp.ibm.com/O=ibm/C=us"
if [ ! -d "$DOCKERKEYS" ]; then mkdir $DOCKERKEYS; fi
if [ ! -d "$DOCKERKEYS/openldap" ]; then mkdir $DOCKERKEYS/openldap; fi
if [ ! -d "$DOCKERKEYS/postgresql" ]; then mkdir $DOCKERKEYS/postgresql; fi
if [ ! -d "$DOCKERKEYS/isvaop" ]; then mkdir $DOCKERKEYS/isvaop; fi
if [ ! -d "$DOCKERKEYS/isvaop/personal" ]; then mkdir $DOCKERKEYS/isvaop/personal; fi
if [ ! -d "$DOCKERKEYS/isvaop/signer" ]; then mkdir $DOCKERKEYS/isvaop/signer; fi
if [ ! -d "$DOCKERKEYS/iviadc" ]; then mkdir $DOCKERKEYS/iviadc; fi
if [ ! -d "$DOCKERKEYS/isvawrp" ]; then mkdir $DOCKERKEYS/isvawrp; fi

# Create a key/cert we can use for webseal which can be imported by the OP and DC containers
# The PKCS12 needs to be imported to the default WebSEAL runtime keystore (pdsrv) once the ivia-config
# container has started.
if [ ! -f "$DOCKERKEYS/isvawrp/isvawrp.pem" ] || [ ! -f "$DOCKERKEYS/isvawrp/isvawrp.key" ]
then
    echo "Creating IVIA WebSEAL Reverse Proxy certificate files"
    openssl req -newkey rsa:4096 -nodes -inform PEM -keyout $DOCKERKEYS/isvawrp/isvawrp.key -x509 -days 3650 -out $DOCKERKEYS/isvawrp/isvawrp.pem -subj $ISVAWRP_CERT_DN -addext "subjectAltName = DNS:www.iamlab.ibm.com, DNS:iviawrprp1, DNS:iviawrprp1:9443"
    openssl pkcs12 -export -out $DOCKERKEYS/isvawrp/isvawrp.p12 -inkey $DOCKERKEYS/isvawrp/isvawrp.key -name wrp.ibm.com -in $DOCKERKEYS/isvawrp/isvawrp.pem --passout pass:Passw0rd
else
    echo "ISVADC PKI files found - using existing certificate and key files"
fi
cp "$DOCKERKEYS/isvawrp/isvawrp.pem" ${IVIAOPCONFIG}
cp "$DOCKERKEYS/isvawrp/isvawrp.pem" ${IVIADCCONFIG}


if [ ! -f "$DOCKERKEYS/openldap/ldap.key" ] || [ ! -f "$DOCKERKEYS/openldap/ldap.crt" ]
then
    echo "Creating LDAP certificate files"
  openssl req -x509 -newkey rsa:4096 -keyout $DOCKERKEYS/openldap/ldap.key -out $DOCKERKEYS/openldap/ldap.crt -days 3650 -subj $LDAP_CERT_DN -nodes
else
    echo "LDAP certificate files found - using existing certificate files"
fi

# Same for dhparam.pem file
if [ ! -f "$DOCKERKEYS/openldap/dhparam.pem" ]
then
    echo "Creating LDAP dhparam.pem"
    openssl dhparam -out "$DOCKERKEYS/openldap/dhparam.pem" 2048
else
    echo "LDAP dhparam.pem file found - using existing file"
fi

cp "$DOCKERKEYS/openldap/ldap.crt" "$DOCKERKEYS/openldap/ca.crt"

if [ ! -f "$DOCKERKEYS/postgresql/postgres.key" ] || [ ! -f "$DOCKERKEYS/postgresql/postgres.crt" ]
then
    echo "Creating postgres certificate files"
    openssl req -x509 -newkey rsa:4096 -keyout $DOCKERKEYS/postgresql/postgres.key -out $DOCKERKEYS/postgresql/postgres.crt -days 3650 -subj $POSTGRES_CERT_DN -nodes -addext "subjectAltName = DNS:postgresql"
else
    echo "Postgres certificate files found - using existing certificate files"
fi

cat  "$DOCKERKEYS/postgresql/postgres.crt" "$DOCKERKEYS/postgresql/postgres.key" > "$DOCKERKEYS/postgresql/server.pem"
cp "$DOCKERKEYS/postgresql/postgres.crt" ${IVIAOPCONFIG}

if [ ! -f "$DOCKERKEYS/isvaop/personal/isvaop.key" ] || [ ! -f "$DOCKERKEYS/isvaop/signer/isvaop.pem" ]
then
    echo "Creating ISVAOP certificate files"
    openssl req -newkey rsa:2048 -nodes -inform PEM -keyout $DOCKERKEYS/isvaop/personal/isvaop.key -x509 -days 3650 -out $DOCKERKEYS/isvaop/signer/isvaop.pem -subj $ISVAOP_CERT_DN -addext "subjectAltName = DNS:isvaop"
    chmod g+r $DOCKERKEYS/isvaop/personal/isvaop.key
else
    echo "ISVAOP certificate files found - using existing certificate files"
fi
cp "$DOCKERKEYS/isvaop/personal/isvaop.key" ${IVIAOPCONFIG}
cp "$DOCKERKEYS/isvaop/signer/isvaop.pem" ${IVIAOPCONFIG}

if [ ! -f "$DOCKERKEYS/iviadc/iviadc.pem" ] || [ ! -f "$DOCKERKEYS/iviadc/iviadc.key" ]
then
    echo "Creating IVIADC certificate files"
    openssl req -newkey rsa:4096 -nodes -inform PEM -keyout $DOCKERKEYS/iviadc/iviadc.key -x509 -days 3650 -out $DOCKERKEYS/iviadc/iviadc.pem -subj $ISVADC_CERT_DN -addext "subjectAltName = DNS:iviadc"
    chmod g+r $DOCKERKEYS/iviadc/iviadc.key
else
    echo "ISVADC PKI files found - using existing certificate and key files"
fi
#cat "$DOCKERKEYS/iviadc/iviadc.key" "$DOCKERKEYS/iviadc/iviadc.pem" > ${IVIADCCONFIG}/keydb.pem
cp "$DOCKERKEYS/iviadc/iviadc.pem" ${IVIADCCONFIG}/
cp "$DOCKERKEYS/iviadc/iviadc.key" ${IVIADCCONFIG}/
cp "$DOCKERKEYS/postgresql/postgres.crt" ${IVIADCCONFIG}/

if [ ! -f "${IVIADCCONFIG}/config.yml" ] && [ -f "${IVIADCCONFIG}/config.template" ]; then
    read -p "Digital Credential License Code: [invalid_dc_code]" DC_CODE
    if [ -z "$DC_CODE" ]; then
        DC_CODE="invalid_dc_code"
    fi
    sed -e "s|@@ISVADC_LICENSE@@|$DC_CODE|g" "${IVIADCCONFIG}/config.template" > "${IVIADCCONFIG}/config.yml"
fi
