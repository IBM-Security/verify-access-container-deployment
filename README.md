# IBM Verify Identity Access - Container Deployment

## Table of Contents

- [Version Information](#version-information)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
- [Common Configuration](#common-configuration)
- [Deployment Methods](#deployment-methods)
  - [Docker Compose](#docker-compose)
  - [Native Docker](#native-docker)
  - [Kubernetes](#kubernetes)
  - [Helm](#helm)
  - [OpenShift](#openshift)
- [Automated Configuration](#automated-configuration)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)
- [License](#license)

## Version Information

**Current Version:** IBM Verify Identity Access v11.0.3.0

## Quick Start

Get started with Docker Compose in 4 steps:

```bash
# 1. Generate PKI certificates
./common/create-ivia-pki.sh

# 2. Create key shares
cd compose && ./create-keyshares.sh

# 3. Deploy containers
cd iamlab && docker-compose up -d

# 4. Access the LMI
# Open https://127.0.0.2 in your browser
```

**Default credentials:** `admin` / `Passw0rd` (⚠️ Change in production!)

## Prerequisites

### System Requirements

- Docker or Podman with Docker Compose
- Write access to `$HOME` and `/tmp`
- Available local IP addresses (see [Common Configuration](#common-configuration))

### Required Setup

**1. Generate PKI Certificates**

Before any deployment, create keystores:

```bash
./common/create-ivia-pki.sh
```

This creates [`local/dockerkeys`](local/dockerkeys) with keystores for:
- PostgreSQL
- OpenLDAP
- WebSEAL Reverse Proxy
- OIDC Provider container
- Digital Credential container

**2. Configure Hostnames**

Add these entries to `/etc/hosts`:

```
127.0.0.2  lmi.iamlab.ibm.com
127.0.0.3  www.iamlab.ibm.com
```

⚠️ **Security Note:** All default passwords are `Passw0rd` - change these for production use!

## Deployment Options

Choose the deployment method that fits your needs:

| Method | Best For | Complexity | Production Ready | Directory |
|--------|----------|------------|------------------|-----------|
| **Docker Compose** | Development, Testing | ⭐ Low | ❌ No | [`compose/`](compose/) |
| **Native Docker** | Local Development | ⭐ Low | ❌ No | [`docker/`](docker/) |
| **Kubernetes** | Production, Cloud | ⭐⭐ Medium | ✅ Yes | [`kubernetes/`](kubernetes/) |
| **Helm** | Production, Cloud | ⭐⭐ Medium | ✅ Yes | [`helm/`](helm/) |
| **OpenShift** | Enterprise | ⭐⭐⭐ High | ✅ Yes | [`openshift/`](openshift/) |

## Common Configuration

All deployment methods use these shared settings (configured in [`common/env-config.sh`](common/env-config.sh)):

### Network Configuration

| IP Address | Hostname | Purpose |
|------------|----------|---------|
| 127.0.0.2 | lmi.iamlab.ibm.com | Management Interface (LMI) |
| 127.0.0.3 | www.iamlab.ibm.com | Web Reverse Proxy |

To use different IP addresses, modify [`common/env-config.sh`](common/env-config.sh) and run [`compose/update-env-file.sh`](compose/update-env-file.sh) for Docker Compose deployments.

### Shared Directory

Docker Compose creates `$HOME/dockershare` for shared data. To use a different directory, update:
- [`common/env-config.sh`](common/env-config.sh)
- Docker Compose YAML files

## Deployment Methods

### Docker Compose

**Location:** [`compose/`](compose/)

#### Setup Steps

1. **Create key shares:**
   ```bash
   cd compose
   ./create-keyshares.sh
   ```

2. **Deploy containers:**
   ```bash
   cd iamlab
   docker-compose up -d
   ```

3. **Verify deployment:**
   ```bash
   docker-compose ps
   curl -k https://127.0.0.2
   ```

#### Cleanup

```bash
docker-compose down -v
```

#### Advanced Configuration

For base layer configuration with automated setup, see [`compose/base_layer/README.md`](compose/base_layer/README.md).

---

### Native Docker

**Location:** [`docker/`](docker/)

#### Setup Steps

1. **Run setup script:**
   ```bash
   cd docker
   ./docker-setup.sh
   ```

2. **Access LMI:**
   Open https://127.0.0.2

#### Cleanup

```bash
./cleanup.sh
```

---

### Kubernetes

**Location:** [`kubernetes/`](kubernetes/)

#### Prerequisites

- `kubectl` installed and configured
- Access to a Kubernetes cluster (Minikube, GKE, EKS, etc.)

#### Setup Steps

1. **Create secrets:**
   ```bash
   cd kubernetes
   ./create-secrets.sh
   ```

2. **Create config map:**
   ```bash
   ./create-configmap.sh
   ```

3. **Deploy resources:**
   ```bash
   kubectl create -f <YAML file>
   ```

   Available YAML files:
   - [`ivia-minikube.yaml`](kubernetes/ivia-minikube.yaml) - Minikube / Docker Desktop
   - [`ivia-ibmcloud.yaml`](kubernetes/ivia-ibmcloud.yaml) - IBM Cloud Free
   - [`ivia-ibmcloud-pvc.yaml`](kubernetes/ivia-ibmcloud-pvc.yaml) - IBM Cloud Paid
   - [`ivia-google.yaml`](kubernetes/ivia-google.yaml) - Google Cloud

4. **Access LMI:**
   ```bash
   ./lmi-access.sh
   # Then open https://localhost:9443
   ```

#### Post-Deployment Configuration

⚠️ **Important:** Set the `cfgsvc` user password in LMI to match the `configreader` secret (default: `Passw0rd`):
- Navigate to **System → Account management** in LMI
- Update the password for user `cfgsvc`


#### Advanced Configuration

For base layer configuration, see [`kubernetes/base_layer/README.md`](kubernetes/base_layer/README.md).

---

### Helm

**Location:** [`helm/`](helm/)

#### Prerequisites

- `kubectl` and `helm` installed and configured
- Access to a Kubernetes cluster

#### Setup Steps

1. **Create secrets:**
   ```bash
   cd helm
   ./create-secrets.sh
   ```

2. **Install release:**
   ```bash
   ./helm3-install.sh
   ```

   This creates a release named `iamlab`. The output includes connection information for LMI and Reverse Proxy services.

#### Cleanup

```bash
./cleanup.sh
```

#### Using Helm Repository

The charts are also available in the IBM Security incubator repository:

```bash
helm repo add ibm-security-incubator https://raw.githubusercontent.com/IBM-Security/helm-charts/master/repo/incubator
helm repo update
```

#### Chart Enhancements (v1.3.0+)

Version 10.0.2.0+ allows service names to be configured, enabling configuration archives from other environments without CoreDNS modifications. See chart release notes for details.

---

### OpenShift

**Location:** [`openshift/`](openshift/)

#### Prerequisites

- OpenShift 4.2+ (for lightweight containers with default security context)
- `oc` utility installed and configured
- Cluster administrator access (for security setup)

#### Setup Steps

**1. Login and create project:**
```bash
oc login -u developer -p developer
oc new-project <project>
```

**2. Configure security (as cluster admin):**
```bash
oc login -u kubeadmin -p <password> -n <project>
./setup-security.sh
```

This creates security constraints for:
- Configuration container (setuid/setgid permissions)
- PostgreSQL (non-root user)
- OpenLDAP (root user)

**3. Create secrets (as standard user):**
```bash
oc login -u developer -p developer -n <project>
./create-secrets.sh
```

**4. Load templates:**
```bash
oc create -f verify-identity-access-openldap-template.yaml
oc create -f verify-identity-access-postgresql-template.yaml
oc create -f verify-identity-access-templates-openshift4.yaml
oc create -f verify-access-operator-template.yaml
```

**5. Deploy applications:**

Via console:
1. Open OpenShift console
2. Select **+Add → From Catalog**
3. Search for "verify"
4. Select and deploy template

Via command line:
```bash
# List available templates
oc new-app -S --template=verify

# View template parameters
oc describe template verify-identity-access-config

# Deploy template
oc new-app --template verify-identity-access-config \
  -p ADMIN_PW=Passw0rd \
  -p CONFIG_PW=Passw0rd
```

#### Accessing Services

**LMI Access:**
```bash
./lmi-access.sh
# Then open https://localhost:9443
```

For management access, create a route using [`lmi-route.yaml`](openshift/lmi-route.yaml).

**Web Proxy Access:**
OpenShift's web proxy routes traffic to the Reverse Proxy. Determine the IP address and add to `/etc/hosts`:
```
<IP>  www.iamlab.ibm.com
```

#### Operator Deployment

For automated production container management, see the [Operator Deployment Guide](openshift/alt-deployment-configs/operator/README.md).

## Automated Configuration

New deployments can be automatically configured using the `ibmvia-autoconf` Python package.

### Prerequisites

- PKI files in the configuration directory (copy or symlink from [`local/dockerkeys`](local/dockerkeys))
- [`env.properties`](configuration/env.properties) file configured with deployment details

### Example: Docker Compose Configuration

```bash
cd configuration

# Link PKI directory
ln -s ../local/dockerkeys pki

# Install configuration tool
pip install ibmvia-autoconf

# Load environment variables
source env.properties

# Run initial configuration
python -m ibmvia_autoconf

# Apply WebSEAL configuration
export ISVA_CONFIG_YAML=webseal_authsvc_login.yaml
python -m ibmvia_autoconf
```

### What Gets Configured

The automation performs:
1. License acceptance
2. SSL database configuration
3. Runtime environment setup
4. WebSEAL instance creation
5. AAC authentication setup

## Backup and Restore

### Creating Backups

Each deployment method includes a backup script:

```bash
# Docker Compose
./compose/ivia-backup-compose.sh

# Native Docker
./docker/ivia-backup-docker.sh

# Kubernetes
./kubernetes/ivia-backup-kubernetes.sh

# Helm
./helm/ivia-backup-helm.sh

# OpenShift
./openshift/ivia-backup-openshift.sh
```

**Backup contents:**
- PKI certificates from [`local/dockerkeys`](local/dockerkeys)
- OpenLDAP directory content
- PostgreSQL database content
- Configuration snapshot from config container

### Restoring from Backup

1. **Delete existing keystores:**
   ```bash
   rm -rf local/dockerkeys
   ```

2. **Restore keys:**
   ```bash
   ./common/restore-keys.sh <backup-archive.tar>
   ```

3. **Deploy environment** (follow setup steps for your chosen method)

4. **Restore configuration:**
   ```bash
   # Use the appropriate restore script for your deployment
   ./compose/ivia-restore-compose.sh <backup-archive.tar>
   ```

## Troubleshooting

### Common Issues

**Issue:** Cannot access LMI at https://127.0.0.2

**Solutions:**
- Verify containers are running: `docker-compose ps` or `kubectl get pods`
- Check hostname resolution: `ping lmi.iamlab.ibm.com`
- Verify `/etc/hosts` entries are correct
- Check firewall rules allow connections to ports 443/9443

---

**Issue:** Permission denied errors

**Solutions:**
- Ensure write access to `$HOME` and `/tmp`
- For Docker Compose: Check `$HOME/dockershare` permissions
- For Kubernetes: Verify PVC permissions and storage class

---

**Issue:** PKI/Certificate errors

**Solutions:**
- Verify [`common/create-ivia-pki.sh`](common/create-ivia-pki.sh) completed successfully
- Check [`local/dockerkeys`](local/dockerkeys) directory exists and contains files
- Ensure certificates are readable: `ls -la local/dockerkeys/`

---

**Issue:** Configuration snapshots not accessible

**Solutions:**
- Verify `cfgsvc` user password matches `configreader` secret
- Check configuration container is running
- Review container logs for errors

---

**Issue:** Port conflicts

**Solutions:**
- Check if ports 443, 9443, 30443 are already in use: `netstat -tuln | grep -E '443|9443|30443'`
- Modify port mappings in deployment YAML files
- Update [`common/env-config.sh`](common/env-config.sh) if using different IPs

## Resources

### Documentation

- **Docker Cookbook:** [Download from Security Learning Academy](http://ibm.biz/Verify_Access_Docker_Cookbook)
  - Covers Docker concepts, container deployment, and initial configuration

- **Kubernetes Cookbook:** [Security Learning Academy Course](https://www.securitylearningacademy.com/course/view.php?id=6860)
  - Requires access to a Kubernetes cluster (hosted or local via Minikube)

- **Official Documentation:** [IBM Knowledge Center](https://www.ibm.com/support/knowledgecenter/en/SSPREK/welcome.html)

### Community Support

For questions about deployment or IBM Security Verify:
- **IAM Community:** https://ibm.biz/iamcommunity

### Related Repositories

- **Helm Charts:** https://github.com/ibm-security/helm-charts

## License

The contents of this repository are open-source under the Apache 2.0 license.

```
Copyright 2018-2026 International Business Machines

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
