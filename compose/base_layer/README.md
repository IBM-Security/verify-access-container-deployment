# Docker Compose Base Layer Configuration

This guide configures IBM Verify Access containers to a "base layer" state using Docker Compose or Podman Compose. At this stage, containers can bootstrap successfully but require additional configuration for production use.

## Prerequisites

### System Requirements
- Docker or Podman installed and running
- Docker Compose or Podman Compose installed
- Python 3.x and pip installed
- Access to IBM Verify Access container images

### Required Files

Generate the following PKI and configuration files before proceeding. See [`../../common/create-ivia-pki.sh`](../../common/create-ivia-pki.sh) for automation.

| File | Purpose | Location |
|------|---------|----------|
| `ldap.crt` | LDAP server certificate | Current working directory |
| `postgres.crt` | PostgreSQL database certificate | Current working directory |
| `isvawrp.p12` | WebSEAL reverse proxy keystore | Current working directory |
| `isvaop.pem` | OIDC Provider certificate | Current working directory |
| `req_openid_config.lua` | OpenID request transformation rules | Current working directory |
| `rsp_openid_config.lua` | OpenID response transformation rules | Current working directory |

### Deployment Requirements
- Deploy Verify Identity Access containers using [`iamlab/docker-compose.yaml`](iamlab/docker-compose.yaml)
- Obtain a trial license from [IBM Verify Access Trial Site](https://isva-trial.verify.ibm.com/)

## Assumptions

This configuration assumes:

- **Deployment file:** Containers deployed via [`iamlab/docker-compose.yaml`](iamlab/docker-compose.yaml)
- **Hostnames configured:**
  - Management interface: `lmi.iamlab.ibm.com`
  - Reverse proxy: `www.iamlab.ibm.com`
- **DNS/hosts file:** These hostnames resolve to your Docker host (typically add to `/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`)

> **Note:** If your environment differs, update [`base_layer.yaml`](base_layer.yaml) accordingly.

## What This Configuration Does

The automation configures the `ivia-config` container with the following steps:

1. **Accept EULA** - Accepts IBM license agreement
2. **Import PKI certificates** - Establishes trust for database, LDAP, OIDC Provider (`iviaop`), and Distributed Cache (`iviadc`)
3. **Configure High-Volume Database** - Sets up PostgreSQL connection for runtime data storage
4. **Import trial license** - Activates IBM Verify Access features
5. **Configure WebSEAL** - Sets up user registry and policy server integration
6. **Create reverse proxy instance** - Establishes `rp1` reverse proxy instance
7. **Create junction** - Routes traffic to the OIDC Provider (`iviaop`) container
8. **Configure LUA transformations** - Enables `.well-known` endpoints for OIDC discovery
9. **Enable distributed session cache** - Configures session sharing across container instances

## Installation & Execution

### Option 1: Manual Execution

1. **Install the configuration tool:**
   ```bash
   pip install ibmvia_autoconf
   ```

2. **Set environment variables:**
   ```bash
   export IVIA_CONFIG_YAML=base_layer.yaml           # Configuration file to use
   export IVIA_MGMT_URL=https://lmi.iamlab.ibm.com   # Management interface URL
   export MGMT_OLD_PWD=admin                         # Default admin password
   export MGMT_PWD=betterThanPassw0rd               # New admin password (change this!)
   export IVIA_CONFIG_BASE=$(pwd)                    # Directory containing config files
   ```

3. **Run the configuration:**
   ```bash
   python -m ibmvia_autoconf
   ```

### Option 2: Automated Script

Use the provided shell script for automated setup:
```bash
./config.sh
```

### Verification

After successful execution, verify the configuration:

1. **Check management interface accessibility:**
   ```bash
   curl -k https://lmi.iamlab.ibm.com
   ```

2. **Check reverse proxy accessibility:**
   ```bash
   curl -k https://www.iamlab.ibm.com
   ```

3. **Review container logs for errors:**
   ```bash
   docker compose -f iamlab/docker-compose.yaml logs ivia-config
   # Or for Podman:
   podman-compose -f iamlab/docker-compose.yaml logs ivia-config
   ```

4. **Verify all containers are running:**
   ```bash
   docker compose -f iamlab/docker-compose.yaml ps
   # Or for Podman:
   podman-compose -f iamlab/docker-compose.yaml ps
   ```

## Troubleshooting

### Common Issues

**Issue:** `pip install ibmvia_autoconf` fails
- **Solution:** Ensure Python 3.x and pip are installed: `python3 --version && pip3 --version`
- **Solution:** Try using pip3 explicitly: `pip3 install ibmvia_autoconf`

**Issue:** Connection refused to management URL
- **Solution:** Verify containers are running: `docker compose -f iamlab/docker-compose.yaml ps`
- **Solution:** Check container networking: `docker network ls` and `docker network inspect <network_name>`
- **Solution:** Verify hostname resolution: Add entries to `/etc/hosts` if needed

**Issue:** Certificate errors during configuration
- **Solution:** Ensure all PKI files are present in `$IVIA_CONFIG_BASE` directory: `ls -la *.crt *.p12 *.pem`
- **Solution:** Verify file permissions are readable: `chmod 644 *.crt *.pem && chmod 600 *.p12`

**Issue:** Authentication failures
- **Solution:** Verify `MGMT_OLD_PWD` matches the current admin password
- **Solution:** Check if password was already changed in a previous run

**Issue:** Port conflicts
- **Solution:** Ensure ports 443, 9443 are not already in use: `netstat -tuln | grep -E '443|9443'`
- **Solution:** Update port mappings in [`iamlab/docker-compose.yaml`](iamlab/docker-compose.yaml) if needed

**Issue:** Volume mount permissions (especially with Podman)
- **Solution:** Check SELinux context: `ls -Z` and add `:z` or `:Z` suffix to volume mounts if needed
- **Solution:** Run with appropriate user permissions or adjust volume ownership

## Next Steps

After completing base layer configuration:

1. **Configure additional junctions** for your backend applications
2. **Set up authentication policies** and access control rules
3. **Configure federation and SSO** for identity provider integration
4. **Review security hardening guidelines** in IBM documentation
5. **Set up monitoring and logging** for production environments
6. **Create snapshot** of your configuration

## Related Files

- [`base_layer.yaml`](base_layer.yaml) - Configuration definitions for automation
- [`config.sh`](config.sh) - Automated setup script
- [`iamlab/docker-compose.yaml`](iamlab/docker-compose.yaml) - Docker Compose deployment manifest
- [`iamlab/.env`](iamlab/.env) - Environment variables for Docker Compose
- [`req_openid_config.lua`](req_openid_config.lua) - OpenID request transformation rules
- [`rsp_openid_config.lua`](rsp_openid_config.lua) - OpenID response transformation rules
- [`../../common/create-ivia-pki.sh`](../../common/create-ivia-pki.sh) - PKI generation script
- [`../ivia-backup-compose.sh`](../ivia-backup-compose.sh) - Backup utility
- [`../ivia-restore-compose.sh`](../ivia-restore-compose.sh) - Restore utility
