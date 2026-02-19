#!/bin/bash

# Get directory for this script
RUNDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -z "$RUNDIR" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

. ${RUNDIR}/../common/env-config.sh

if [ ! -d "${IVIAOPCONFIG}" ] 
then
  echo "OIDC OP configuration files not found at ${IVIAOPCONFIG}"
  exit 1
fi

if [ ! -d "${IVIADCCONFIG}" ] 
then
  echo "Digital Credential configuration files not found at ${IVIADCCONFIG}"
  exit 1
fi

# Create secret for TLS certificates used by this container
echo "Deleting confimap"
kubectl delete configmap iviaop-config
kubectl delete configmap iviadc-config
echo "Creating confimap for iviaop"
kubectl create configmap iviaop-config --from-file=${IVIAOPCONFIG}
echo "Creating confimap for iviadc"
kubectl create configmap iviadc-config --from-file=${IVIADCCONFIG}
echo "Done."
