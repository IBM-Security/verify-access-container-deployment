#!/bin/bash
# This script will fetch the user/rw.pwd from the installed Verify Access Operator,
# then attempt to upload the given snapshot ID to the Operator's managed snapshot 
# service. It will do this from a temporary pod created in the current namespace.
# It will use a minified curl contaienr to upload the snapshot. Your cluster must
# be able to pull the minified curl container from a registry.
#
# Note: if your snapshot is larger than 1GB, you will need to increase the volume limit.

for COMMAND in jq oc base64 basename; do
    if ! command -v "$COMMAND" &> /dev/null
    then
        echo "$COMMAND CLI tool missing"
        exit 1
    fi
done

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 <snapshot>"
    exit 2
fi

SNAPSHOT_PATH="$1"
SNAPSHOT_FILE="$(basename "$SNAPSHOT_PATH")"

if ! echo "$SNAPSHOT_FILE" | grep -qE '^ivia_[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+_[a-zA-Z0-9\-]+\.snapshot$'; then
    echo "ERROR: Invalid snapshot filename: $SNAPSHOT_FILE"
    echo "Permitted format: ivia_[version]_[snapshot-id].snapshot"
    echo "eg: ivia_11.0.2.0_config-26-05-31.snapshot"
    exit 5
fi

# Get the verify-access-operator's properties to upload snapshots
OPERATOR_YAML="$(oc get secret -n openshift-operators verify-access-operator -o json )"

if [ -z "$OPERATOR_YAML" ]; then
    echo "Verify Access Operator snapshot service secret does not exist or can not be read"
    exit 3
fi


URL="$( echo "$OPERATOR_YAML" | jq -cr '.data.url' | base64 -d )"
USER="$( echo "$OPERATOR_YAML" | jq -cr '.data.user' | base64 -d )"
RWPWD="$( echo "$OPERATOR_YAML" | jq -cr '.data."rw.pwd"' | base64 -d )"
TLS_CERT="$( echo "$OPERATOR_YAML" | jq -cr '.data."tls.cert"' | base64 -d )"


echo "Operator URL: ${URL}"

# Create a temporary secret with the TLS cert
echo "Creating temporary TLS secret..."
oc create secret generic snapshot-uploader-tls \
  --from-literal=operator.crt="${TLS_CERT}" \
  --dry-run=client -o yaml | oc apply -f -

# Create uploader pod with tmpfs for snapshot
echo "Creating uploader pod..."
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: snapshot-uploader
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: uploader
    image: curlimages/curl:latest
    command: ['sleep', '3600']
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      runAsUser: 100
    volumeMounts:
    - name: snapshot-storage
      mountPath: /tmp/snapshots
    - name: tls-cert
      mountPath: /tmp/certs
      readOnly: true
  volumes:
  - name: snapshot-storage
    emptyDir:
      sizeLimit: 1Gi
  - name: tls-cert
    secret:
      secretName: snapshot-uploader-tls
  restartPolicy: Never
EOF

echo "Waiting for uploader pod to be ready..."
oc wait --for=condition=Ready pod/snapshot-uploader --timeout=120s

echo "Copying snapshot to uploader pod..."
oc cp "$SNAPSHOT_PATH" "snapshot-uploader:/tmp/snapshots/${SNAPSHOT_FILE}"

echo "Uploading snapshot to operator..."
oc exec snapshot-uploader -- \
  curl -v --cacert /tmp/certs/operator.crt -u "${USER}:${RWPWD}" \
  "${URL}/snapshots/${SNAPSHOT_FILE}" -F "file=@/tmp/snapshots/${SNAPSHOT_FILE}"

UPLOAD_STATUS=$?

echo ""
echo "Cleaning up..."
oc delete pod snapshot-uploader
oc delete secret snapshot-uploader-tls

if [ "${UPLOAD_STATUS}" -ne "0" ]; then
  echo "ERROR: Failed to upload snapshot to operator"
  exit 1
fi
echo "Snapshot uploaded successfully!"