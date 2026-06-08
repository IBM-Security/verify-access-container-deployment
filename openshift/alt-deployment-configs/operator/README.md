# Deploying Verify Identity Access using the OpenShift Operator

1 - install operator (check version is 26.5 and OpenShift can pull images from icr.io)

>Note: The operator requires write access to the `/tmp` and `/data` directories in its file system.

2 - Deploy IVIA using template + use Ansible (or other) to configure containers with required junctions, access policies, federations, ect.

Demo does not include the OpenLDAP and PostgreSQL services. Administrators should deploy the required LDAP and HVDB
services before creating containers.

    oc process -f oshift-ivia-standalone-template.yaml \
        -p APP_NAME='ivia-operator-config-demo' \
        -p IVIA_VERSION='11.0.2.0' \
        -p CONFIG_SERVICE='iviaconfig' \
        -p RUNTIME_SERVICE='iviaruntime' \
        -p WEBSEAL_SERVICE='iviawebseal' \
        -p DSC_SERVICE='iviadsc' \
        -p IVIA_IMAGE_NAME='icr.io/ivia/ivia' \
        -p WRP_INSTANCE='default' \
        -p DSC_INSTANCE='1' \
        -p TIMEZONE='Etc/UTC' \
        -p SERVICE_ACCOUNT='verifyaccess' \
        | oc create -f -

3 - Update the `verify-access-operator` secret with the rw.pwd for the Operator's snapshot management service.

`oc set data secret/verify-access-operator rw.pwd='random_string'`

Secrets for the ibm verify access operator can be read from openshift operator's namespace
`oc get secret verify-access-operator -n openshift-operators -o yaml`

4 - Test deployment as required


A simple bash script is provided to read the verify-access-operator secret from the `openshift-operators` namespace, start a curl container and upload the specified snapshot to the Operator's snapshot manager service.

    $ bash upload_snapshot_to_operator.sh <configuration_container_id> <snapshot_name>

eg: `$ bash upload_snapshot_to_operator.sh ivia_11.0.3.0_operator-template.snapshot`

>Note: the "snapshotId" property in the operator only refers to the "operator-template" substring in the snapshot file name.

5 - Deploy containers using the Deploy Operator template
    be careful of "stale" secrets in your namespace: `oc delete secret verify-access-operator`


    oc process -f oshift-ivia-operator-template.yaml \
        -p APP_NAME='verify-identity-access-operator-demo' \
        -p IVIA_BASE_IMAGE_NAME='icr.io/ivia/ivia' \
        -p SERVICE_ACCOUNT='verifyaccess' \
        -p IVIA_VERSION='11.0.2.0' \
        -p INSTANCE='default' \
        -p SNAPSHOT='operator-template' \
        -p LANGUAGE='en_US.utf8' \
        -p WRP_REPLICAS='1' \
        -p RUNTIME_REPLICAS='1' \
        -p DSC_REPLICAS='1' \
        | oc create -f -
