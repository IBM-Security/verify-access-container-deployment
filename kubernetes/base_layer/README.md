# Configuration
This readme documents how to configure the various Verify Access containers to a "base layer" configuration.
In this state, containers have sufficient configuration to bootstrap correctly, but likely still cannot do 
anything particularly useful.

# Requirements
- generate required PKI and configuration files and have copies of them in your current working directory
  * required files: `ldap.crt`, `postgres.crt`, `isvawrp.p12`, `isvaop.pem`, `req_openid_config.lua`
    and `rsp_openid_config.lua`
- deploy Verify Identity Access containers using `ivia-minikube.yaml` or equivalent
- get a trial license from [IVIA trial site](https://isva-trial.verify.ibm.com/)

## Configuration steps performed on the ivia-config container
- accept EULA
- import PKI for database, ldap, iviaop and iviadc containers
- set the High-Volume Database connection
- import the trial license
- configure the WebSEAL user registry / policy server
- create the `rp1` reverse proxy instance
- create a junction to the `iviaop` container
- create LUA http transformation rules for the .well-known endpoints required by the `iviadc` container
- configure the distributed session cache service

This automated configuration assumes that the Verify Identity Access containers have been deployed with 
the configuration defined in the `ivia-minikube.yaml` file. If your environment differs from this, you 
may need to update the provided configuration.

The provided automation also assumes that you have set up host/domain names `lmi.iamlab.ibm.com` for the 
management interface and `www.iamlab.ibm.com` for the `rp1` reverse proxy instance.

# Running the configuration tool
Once you have copies of the required configuration files, you can install and run the configuration tool 
as follows:

```bash
pip install ibmvia_autoconf
export IVIA_CONFIG_YAML=base_layer.yaml
export IVIA_MGMT_URL=https://lmi.iamlab.ibm.com
export MGMT_OLD_PWD=admin
export MGMT_PWD=betterThanPassw0rd
export IVIA_CONFIG_BASE=$(pwd)
python -m ibmvia_autoconf
```

An example shell script which automates the above steps is provided at `base_layer.sh`
