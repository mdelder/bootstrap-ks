#-----OLD CODE THAT IS NOW IN https://github.com/gurnben/cloud-clis-base-image-----#
# Saving for legacy/if we want to make a proper base image rather than my own.
# FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# # Install microdnf packages: tar/gzip, curl, git, jq, htpasswd
# RUN microdnf update -y && microdnf install -y tar gzip curl git jq httpd-tools findutils
# RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
# RUN echo -e "[azure-cli]\n\
# name=Azure CLI\n\
# baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
# enabled=1\n\
# gpgcheck=1\n\
# gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo
# RUN microdnf install azure-cli

#-----END OLD-----#

# Pull my own homemade base image that uses the above old code.
FROM quay.io/gurnbenibm/cloudclisbase:latest
# Install kustomize
RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_linux_amd64.tar.gz -o kustomize_v4.1.3_linux_amd64.tar.gz && \
    tar xzf kustomize_v4.1.3_linux_amd64.tar.gz -C /usr/local/bin && \
    rm kustomize_v4.1.3_linux_amd64.tar.gz && \
    chmod +x /usr/local/bin/kustomize
# Install oc/kubectl
RUN curl -sLO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz && \
    tar xzf openshift-client-linux.tar.gz && chmod +x oc && mv oc /usr/local/bin/oc && \
    chmod +x kubectl && mv kubectl /usr/local/bin/kubectl && rm openshift-client-linux.tar.gz

# Add bootstrap-ks modules
ADD aro/ aro/
ADD aks/ aks/
ADD container-utils/resources resources/
ADD container-utils/provision_wrapper.sh provision_wrapper.sh
ADD container-utils/import_cluster.sh import_cluster.sh
