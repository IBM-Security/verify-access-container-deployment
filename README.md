# Version Information
These assets are for IBM Verify Identity Access v11.0.0.0.
They will also work for older versions (eg. IBM Security Verify Access v10.0.8.0) if version is changed where appropriate.

Assets for v10.0.0.0 (which will also work with v10.0.1.0) are available as a release.  Checkout tag `v10.0.0.0-1`.

Assets for IBM Security Access Manager are available at https://ibm.biz/isamdocker

# Resources
## Cookbooks
### Deployment with Native Docker and Docker Compose
This cookbook describes deployment with Native Docker and Docker Compose.  It covers some docker concepts, deployment of Verify Identity Access containers, and initial configuration of a simple Verify Identity Access system. [Download docker cookbook from Security Learning Academy](http://ibm.biz/Verify_Access_Docker_Cookbook).

### Deployment with Kubernetes
This cookbook describes deployment using Kubernetes.  It requires that you have access to a Kubernetes cluster.  This could be a hosted cluster on a cloud environment or a test environment built using a tool such as Minikube.
https://www.securitylearningacademy.com/course/view.php?id=6860

## Community assistance
If you have questions about deployment, or about IBM Security Verify, you can ask them on the IAM Group of the IBM Security Community: https://ibm.biz/iamcommunity

# Common Requirements and Setup

These scripts expect to have write access to `$HOME` and `/tmp`.

The docker compose scripts will create a `$HOME/dockershare` directory.  If you want to use a different directory, you'll need to modify the common/env-config.sh file AND the docker-compose YAML file.

All passwords set by these scripts are `Passw0rd`.  Obviously this is not a secure password!

# Create Keystores
Before running any other scripts, run `verify-access-container-deployment/common/create-ivia-pki.sh`

This will create the `verify-access-container-deployment/local/dockerkeys` directory and populate it with keystores for PostgreSQL, OpenLDAP, IVIA WebSEAL Reverse proxy, IVIA OIDC Provider, and IVIA Digital Credential containers.

# Native Docker
To set up a native Docker environment, use the files in `verify-access-container-deployment/docker`.

These scripts assume you have the following IP addresses available locally on your Docker system with entries in `/etc/hosts` for the associated hostnames:
- 127.0.0.2 (lmi.iamlab.ibm.com)
- 127.0.0.3 (www.iamlab.ibm.com)

If you want to use other local IP addresses then you'll need to modify the `common/env-config.sh` file.

Run `./docker-setup.sh` script to create docker containers.

You can now connect to the Verify Identity Access LMI at https://127.0.0.2

To clean up the docker resources created, run the `./cleanup.sh` script.

# Docker Compose
To set up an environment with docker-compose, use the files in container-deployment/compose.

These scripts will create the `$HOME/dockershare` directory.

These scripts assume you have the following IP addresses available locally on your Docker system with entries in `/etc/hosts` for the associated hostnames:
- 127.0.0.2 (lmi.iamlab.ibm.com)
- 127.0.0.3 (www.iamlab.ibm.com)

If you want to use other local IP addresses then you'll need to modify the common/env-config.sh file and run `./update-env-file.sh`

Run `./create-keyshares.sh` to copy keys to `$HOME/dockershare/composekeys` directory

Change directory to the `iamlab` directory.

Run command `docker-compose up -d` to create containers.

You can now connect to the Verify Identity Access LMI at https://127.0.0.2

To clean up the docker resources created, run `docker-compose down -v` command.

# Kubernetes
To set up an environment using Kubernetes, use the files in `verify-access-container-deployment/kubernetes`.

These scripts assume that you have the `kubectl` utility installed and that it is configured to talk to your cluster.

First, run `./create-secrets.sh` command to create the secrets required for the environment.

Next, run `./create-configmap.sh` command to create the config map required for the environment.

Then, run `kubectl create -f <YAML file>` to define the resources required.

There are YAML files for the following environments:
- Minikube (`ivia-minikube.yaml`)
   - Also works with Kubernetes included with Docker CE on Mac
- IBM Cloud Free Edition (`ivia-ibmcloud.yaml`)
- IBM Cloud Paid Edition (`ivia-ibmcloud-pvc.yaml`)
- Google (`ivia-google.yaml`)

Once all pods are running, you can run the `./lmi-access.sh` script to start a port-forward session for access to the LMI. With this running, you can access LMI using at https://localhost:9443

If the LMI port-forwarding isn't stable, you can also create a node port or ingress using the provided `iviaconfig-nodeport.yaml` or `iviaconfig-ingress.yaml` files (but this will open your LMI to the world).  If using an ingress, you will need to determine the IP address where this is listening and then point `lmi.iamlab.ibm.com` to it in your `/etc/hosts` file.

To allow worker containers to access configuration snapshots, you must set the password of the `cfgsvc` user in the LMI to match the password set in the `configreader` secret (default is `Passw0rd`).  You can set this password under **System->Account management** in the LMI.

To access the Reverse Proxy you will need to determine an External IP for a Node in the cluster and then connnect to this using https on port 30443.

For Google, access to a NodePort requires the following firewall rule to be created:
`gcloud compute firewall-rules create iviawrp-node-port --allow tcp:30443`

The Minikube YAML file includes an ingress definition for the Reverse Proxy.  To use the ingress, you will need to determine the IP address where this is listening and then point `www.iamlab.ibm.com` to it in your `/etc/hosts` file.

You can add an ingress to the Kubernetes cluster provided by Docker CE on MAC using this command:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml
```

# Helm 3.0
To set up an environment using Helm, use the files in `container-deployment/helm`.

> Enhancements have been made to the Helm chart for v10.0.2.0 (chart version v1.3.0) to allow service names to be set.  This means that the release created can work with configuration archives saved from other environments without the need to modify CoreDNS.  For more details, see the chart release notes.

These scripts assume that you have the `kubectl` and `helm` utilities installed and that they are configured to talk to a cluster.

First, run `./create-secrets.sh` command to create the secrets required for the environment.

Then, run `./helm-install.sh` to run the helm command to create a Security Verify release (called `iamlab`).

The output from this command includes the information you will need to connect to the LMI and Reverse Proxy services.

To delete the release and clean up, run the `./cleanup.sh` command.

The Helm Charts included here are also hosted in the incubator repo at: https://github.com/ibm-security/helm-charts. You can add these as a Helm repo using command:
```
helm repo add ibm-security-incubator https://raw.githubusercontent.com/IBM-Security/helm-charts/master/repo/incubator
```

# OpenShift
To set up an environment using OpenShift, use the files in `verify-access-container-deployment/openshift`.

OpenShift 4.2 or above is required for lightweight containers to work with the default security context.  For older versions your can use the OpenShift 3.x template file.  These instructions are for OpenShift 4.x.

These scripts assume that you have the `oc` utility installed and it is configured to talk to your OpenShift system.

## Login and create project
Login as your standard user:

```oc login -u developer -p developer```

Create a project:

```oc new-project <project>```

## Create and apply security constraints
Although the lightweight worker containers can run with the default service account, additional permissions are required for other components:
- The Verify Identity Access configuration container requires setuid and setgid permissions.
- The postgreSQL container requires permission to run as a non-root user
- The OpenLDAP container requires permission to run as root

To provide these permissions an additional security constraint and a set of service accounts are created.  You must be a cluster administrator to add security constraints and grant them to service accounts.  For example, login as kubeadmin user:

```oc login -u kubeadmin -p xxxxxxxxx -n <project>```

To perform the security setup, run the `./setup-security.sh` command.

## Create secrets
Now login again as your standard user:

```oc login -u developer -p developer -n <project>```

Next, run `./create-secrets.sh` command to create the secrets required for the environment.

## Load templates
Load the templates using the following commands:

```
oc create -f verify-identity-access-openldap-template.yaml
oc create -f verify-identity-access-postgresql-template.yaml
oc create -f verify-identity-access-templates-openshift4.yaml
oc create -f verify-access-operator-template.yaml
```

## Deploy applications
You can deploy applications using either the OpenShift console or using the command line.

### Deploy in OpenShift console
Perform the following actions:
1. Open the OpenShift console
1. Login as your standard user
1. Select **+Add**
1. Select **From Catalog**
1. Use **verify** in search bar
1. Select template and deploy

As part of deploying a template you will get the chance to update the default deploy parameters.

### Deploy on the command line
Use the following command to search for Verify Identity Access templates:
```
oc new-app -S --template=verify
```

To show the parameters available in a template, use the `describe` command. For example:
```
oc describe template verify-identity-access-config
```

To deploy a template, use the `oc new-app` command specifying the template and any parameter overrides you need.  For example:
```
oc new-app --template verify-identity-access-config -p ADMIN_PW=Passw0rd -p CONFIG_PW=Passw0rd
```

## Access LMI and Web Proxy
Once Verify Identity Access is deployed, you can run the `./lmi-access.sh` script to start a port-forward session for access to the LMI.
With this running, you can access LMI using at https://localhost:9443.

If the LMI port-forwarding isn't stable, you can also create a route using the provided `lmi-route.yaml` file (but this will open your LMI to the world).  You will need to determine the IP address where this is listening and then point `lmi.iamlab.ibm.com` to it in your `/etc/hosts` file.

OpenShift includes a web proxy which can route traffic to the Verify Identity Access Reverse Proxy.  You will need to determine the IP address where this is listening and then point `www.iamlab.ibm.com` to it in your `/etc/hosts` file.

To allow worker containers to access configuration snapshots, you must create an LMI user that matches the `configuration read username` and `configuration read password` set during deployment of the configuration container. This is done under **System->Account management** in the LMI. The default username is `cfgsvc` and this user already exists in the LMI.  If you use this username you will only need to set the password.


## OpenShift Operator deployment
The [Operator Deployment Demo](openshift/alt-deployment-configs/operator/README.md) can be used to automate management of 
production containers using the Verify Identity Access Operator.

# Automated Configuration
New deployments can be automatically configured using the `verify-access-autoconf` python package to apply a YAML configuration file. The provided ``first-steps.yaml`` configuration file assumes that you have a copy of the PKI used to deploy the containers in the configuration directory.
This can be done by either copying the files, or using a symbolic link to the directory which contains the required keys/certificates.

The `env.properties` file is used to supply the url, user, secret, and activation codes for the deployment. This file may need to be updated if you 
have made changes to the above deployments.

For example a docker-compose deployment can be configured by executing the following from the ``verify-access-container-deployment/configuration`` directory:

```
ln -s pki $HOME/dockershare/composekeys
pip install verify-access-autoconf
source env.properties
python -m verify_access_autoconf #Accepts licenses, configures SSL databases and runtime environments.
export ISVA_CONFIG_YAML=webseal_authsvc_login.yaml
python -m verify_access_autoconf #Creates a WebSEAL instance and enables AAC authentication.
```


# Backup and Restore

To backup the state of your environment, use the `./isva-backup....sh` script in the directory for the environment you're using.  The backup tar file created will contain:
- Content of the `verify-access-container-deployment/local/dockerkeys` directory
- OpenLDAP directory content
- PostgreSQL database content
- Configuration snapshot from the Verify Identity Access config container

To restore from a backup, perform these steps:

1. Delete the `verify-access-container-deployment/local/dockerkeys` directory
1. Run `verify-access-container-deployment/common/restore-keys.sh <archive tar file>`
1. Complete setup for the environment you want to create (until containers are running)
1. Run `./ivia-restore....sh <archive tar file>` to restore configuration.

# License

The contents of this repository are open-source under the Apache 2.0 licence.

```
Copyright 2018-2021 International Business Machines

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
