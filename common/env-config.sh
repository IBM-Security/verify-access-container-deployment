#!/bin/bash

# This script sets up environment variables for use by the rest of the Verify Identity Access Container Deployment scripts.
# This script is designed to be sourced from within other scripts so that variables are available on exit.

# If IPs or Versions updated here, you must also run compose/update-env-file.sh to update docker-compose project .env file.
# Kubernetes YAML files do not accept environment variables.  They must be updated by hand.

# IP addresses on local machine used for exposing ports from Docker containers.
# These should be mapped in /etc/hosts to appropriate hostnames

# Bind to lmi.iamlab.ibm.com
MY_LMI_IP=127.0.0.2

# Bind to www.iamlab.ibm.com
MY_WEB1_IP=127.0.0.3

# Spare binding if needed
MY_WEB2_IP=127.0.0.4

# Versions
CONTAINER_BASE=us.icr.io/sps-ivia/ivia
ISVA_VERSION=11.0.2.0
LDAP_VERSION=latest
DB_VERSION=11.0.2.0
IVIAOP_VERSION=25.10
IVIADC_VERSION=25.12

# Get directory for this script
PARENT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && cd .. && pwd )"
if [ -z "$PARENT" ] ; then
  echo "Failed to get local path"
  exit 1  # fail
fi

# Location where Keystores will be created
DOCKERKEYS=${PARENT}/local/dockerkeys
IVIAOPCONFIG=${PARENT}/common/isvaop-config
IVIADCCONFIG=${PARENT}/common/iviadc-config
# Location where Docker Shares will be created
# Note that this directory is also hardcoded into YAML files
DOCKERSHARE=${HOME}/dockershare
export DOCKERSHARE
export IVIAOPCONFIG
export IVIADCCONFIG
