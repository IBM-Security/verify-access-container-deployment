#!/bin/bash
# Get directory for this script
RUNDIR="`dirname \"$0\"`"         # relative
RUNDIR="`( cd \"$RUNDIR\" && pwd )`"  # absolutized and normalized
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Get environment from common/env-config.sh
. $RUNDIR/../common/env-config.sh

KEY_DIR=${DOCKERSHARE}/composekeys
OPCONF_DIR=${DOCKERSHARE}/isvaop-config
DCCONF_DIR=${DOCKERSHARE}/iviadc-config
if [ ! -d "$KEY_DIR" ]; then mkdir -p $KEY_DIR; fi
if [ ! -d "$OPCONF_DIR" ]; then mkdir -p $OPCONF_DIR; fi
if [ ! -d "$DCCONF_DIR" ]; then mkdir -p $DCCONF_DIR; fi

if [ ! -f "$DOCKERKEYS/openldap/ldap.key" ] || [ ! -f "$DOCKERKEYS/openldap/ldap.crt" ] || [ ! -f "$DOCKERKEYS/openldap/ca.crt" ] || [ ! -f "$DOCKERKEYS/openldap/dhparam.pem" ] || [ ! -f "$DOCKERKEYS/postgresql/server.pem" ] || [ ! -f "$DOCKERKEYS/isvaop/personal/isvaop.key" ] || [ ! -f "$DOCKERKEYS/isvaop/signer/isvaop.pem" ] || [ ! -f "$DOCKERKEYS/iviadc/iviadc.key" ] || [ ! -f "$DOCKERKEYS/iviadc/iviadc.pem" ]

then
        echo "Key files not found.  Restore or create keys before running this script."
        exit 1
fi

echo -n "Creating key shares at $KEY_DIR . . . "
cp -R $DOCKERKEYS/* $KEY_DIR/
echo "Done."

echo -n "Creating isvaop config shares at $OPCONF_DIR . . . "
cp -R $IVIAOPCONFIG/* $OPCONF_DIR/
echo "Done."
echo -n "Creating isvadc config shares at $DCCONF_DIR . . . "
cp -R $IVIADCCONFIG/* $DCCONF_DIR/
echo "Done."
read -p "Digital Credential License Activation Code: " DC_LICENSE
if [ ! -z "${DC_LICENSE}" ]; then
    sed -e "s|@@ISVADC_LICENSE@@|${DC_LICENSE}|g" $DCCONF_DIR/config.template > $DCCONF_DIR/config.yml
else
    echo "Not updating \"general.license.key\" property in Digital Credential config.yml"
    if [ ! -f $DCCONF_DIR/config.yml ]; then
        cp $DCCONF_DIR/config.template $DCCONF_DIR/config.yml
    fi
fi

echo "Done."
cp $DOCKERKEYS/isvaop/personal/* $OPCONF_DIR
cp $DOCKERKEYS/isvaop/signer/* $OPCONF_DIR
cp $DOCKERKEYS/postgresql/postgres.crt $OPCONF_DIR
cp $DOCKERKEYS/postgresql/postgres.crt $DCCONF_DIR
cp $DOCKERKEYS/isvawrp/isvawrp.pem $DCCONF_DIR
echo "Done."
