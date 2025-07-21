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

cd $RUNDIR/iamlab


echo "Updating .env using common/env-config.sh"
mv .env .env.original
sed  '/_IP/d' .env.original > .env
mv .env .env.original
sed  '/ISVA_VERSION/d' .env.original > .env
mv .env .env.original
sed  '/LDAP_VERSION/d' .env.original > .env
mv .env .env.original
sed  '/IVIAOP_VERSION/d' .env.original > .env
mv .env .env.original
sed  '/DB_VERSION/d' .env.original > .env
mv .env .env.original
sed  '/CONTAINER_BASE/d' .env.original > .env
mv .env .env.original
sed  '/IVIADC_VERSION/d' .env.original > .env
rm .env.original
cat >> .env <<EOF
CONTAINER_BASE=${CONTAINER_BASE}
ISVA_VERSION=${ISVA_VERSION}
LDAP_VERSION=${LDAP_VERSION}
DB_VERSION=${DB_VERSION}
LMI_IP=${MY_LMI_IP}
WEB1_IP=${MY_WEB1_IP}
WEB2_IP=${MY_WEB2_IP}
IVIAOP_VERSION=${IVIAOP_VERSION}
IVIADC_VERSION=${IVIADC_VERSION}
EOF


echo "Done."
