## Azure Red Hat OpenShift (ARO)

This module can be used to install dependencies for Azure Red Hat OpenShift (ARO) provisioning (the `az` cli), provision an ARO cluster, and destroy an ARO cluster provisioned using this utility.  

### Getting Started
*Optionally* run install.sh, this only works on MacOS and Fedora-based Linux instances.  

### Provisioning
1. Set the following env vars before provisioning:

```
export AZURE_USER=<your-azure-username>
export AZURE_PASS=<your-azure-password>
export AZURE_BASE_DOMAIN_RESOURCE_GROUP_NAME=<name-of-your-base-domain-resource-group-name>
export AZURE_BASE_DOMAIN=<your-clusters-base-domain>
export OCP_PULL_SECRET_FILE=<path-to-your-openshift-pull-secret> # Pull secret can be found at https://cloud.redhat.com/openshift/create/local -> "Download pull secret"

# Optional
export CLUSTER_NAME=<some cluster name> # if you set a cluster name, we will use it as a base name for all resources created and append a unique identifier
# if CLUSTER_NAME is not specified, we will use the first 8 characters of the system's username

export AZURE_REGION=<region>  # defaults to eastus
```

2. run `./provision.sh`
3. if successful, you will see a `.json` and `.cred.json` file with metadata for your cluster!

### Cleaning up a cluster
1. run `./destroy.sh <.json file of your cluster metadata>`
