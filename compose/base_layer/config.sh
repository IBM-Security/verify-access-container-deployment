#!/bin/bash
set -x
# Get directory for this script
RUNDIR="`dirname "$0"`"         # relative
RUNDIR="`cd "$RUNDIR" && pwd`"  # absolutized and normalized
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1
fi

. ${RUNDIR}/../../common/env-config.sh
# Collect current PKI
cp $DOCKERKEYS/isvawrp/isvawrp.p12 $RUNDIR/isvawrp.p12
cp $DOCKERKEYS/isvaop/signer/isvaop.pem $RUNDIR/isvaop.pem
cp $DOCKERKEYS/postgresql/postgres.crt $RUNDIR/postgres.crt
cp $DOCKERKEYS/openldap/ldap.crt $RUNDIR/ldap.crt

for FILE in base_layer.yaml postgres.crt ldap.crt isvawrp.p12 isvaop.pem req_openid_config.lua rsp_openid_config.lua; do
    if [ ! -f "$FILE" ]; then
        echo "$FILE configuration file missing from project; not added to working dir [$(pwd)]"
        exit 1
    fi
done

if [ ! -f "ISAM-Trial-IBM.cer" ]; then
    echo "Missing IVIA trial license in $(pwd); obtain a trial from https://isva-trial.verify.ibm.com/"
    echo "Alternatively, obtain product activation codes and update this check"
    exit 1
fi


#echo "Installing configuration tool"
#virtualenv $DOCKERSHARE/pyenv
#source $DOCKERSHARE/pyenv/bin/activate
#pip install ibmvia_autoconf
export IVIA_CONFIG_YAML=base_layer.yaml
export IVIA_MGMT_BASE_URL=https://127.0.0.2:9443
export IVIA_MGMT_OLD_PWD=admin
export IVIA_MGMT_PWD=Passw0rd
export IVIA_MGMT_USER=admin
export IVIA_CONFIG_BASE=$(pwd)
#export IVIA_KUBERNETES_YAML_CONFIG=/tmp/tmp.gLU9O86U74
echo "Running configuration tool"
python -m ibmvia_autoconf | tee base_layer.log
