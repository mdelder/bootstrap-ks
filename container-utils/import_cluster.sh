#!/bin/sh

pushd resources

TMP_KUBECONFIG="${KUBECONFIG}"
WORKING_DIR="/home/tmp"
BOOTSTRAP_KUBECONFIG="${WORKING_DIR}/bootstrap-hub.kubeconfig"

# Prepare Bootstrap Service Account + Permissions

# Assume that the ClusterRole is already applied
# kubectl apply -f bootstrap-cluster-role.yaml
# use `kustomize build` instead of `kubectl apply -k` because
# kustomize will replace the value of `namespace: ` in cluster-ns.yaml
# cp -r bootstrap-cluster-import /home/tmp/
# sed -i.bak -E "s/namespace: .*$/namespace: ${CLUSTER_NAME}/g" ${WORKING_DIR}/bootstrap-cluster-import/kustomization.yaml
# kustomize build ${WORKING_DIR}/bootstrap-cluster-import | kubectl apply -f -

cp -r managedcluster.yaml ${WORKING_DIR}/
sed -i.bak -E "s/name: .*$/name: ${CLUSTER_NAME}/g" "${WORKING_DIR}/managedcluster.yaml"
echo "--- # managedcluster.yaml"
cat "${WORKING_DIR}/managedcluster.yaml"
kubectl apply -f ${WORKING_DIR}/managedcluster.yaml

sleep 10

cp -r klusterlet.yaml ${WORKING_DIR}/
sed -i.bak -E "s/clusterName: .*$/clusterName: ${CLUSTER_NAME}/g" "${WORKING_DIR}/klusterlet.yaml"
echo "--- # klusterlet.yaml"
cat "${WORKING_DIR}/klusterlet.yaml"

# Automatically deleted by the registration controller
#         kubectl create -n ${CLUSTER_NAME} -f - <<EOF
# apiVersion: v1
# kind: Secret
# metadata:
#   name: bootstrap-sa
#   namespace: ${CLUSTER_NAME}
#   annotations:
#     kubernetes.io/service-account.name: system:open-cluster-management:managedcluster:bootstrap:${CLUSTER_NAME}
# type: kubernetes.io/service-account-token
# stringData:
#   token: EMPTY
# EOF

SA_SECRET_NAME=$(oc get sa -n  ${CLUSTER_NAME} -oyaml ${CLUSTER_NAME}-bootstrap-sa -ogo-template='{{range .secrets}}{{ printf "%s\n" .name }}{{end}}' | grep token)
# Let Kubernetes populate the token
sleep 5
kubectl get -n ${CLUSTER_NAME} secrets ${SA_SECRET_NAME}
# TODO Need a way to derive this value
HUB_CLUSTER_API="https://api.demo-east-v475-hvbtt.demo.red-chesterfield.com:6443"

HUB_CLUSTER_NICKNAME="hub"
kubectl get configmap kube-root-ca.crt -n kube-public -ogo-template='{{index .data "ca.crt"}}' > "${WORKING_DIR}/hub-ca.crt"
SA_USER="system:serviceaccount:${CLUSTER_NAME}:bootstrap-sa"
BOOTSTRAP_SA_TOKEN=$(kubectl get -n ${CLUSTER_NAME} secrets ${SA_SECRET_NAME} -o go-template='{{.data.token|base64decode}}')

touch ${BOOTSTRAP_KUBECONFIG}
kubectl config --kubeconfig="${BOOTSTRAP_KUBECONFIG}" set-cluster \
    ${HUB_CLUSTER_NICKNAME} \
    --server=${HUB_CLUSTER_API} \
    --certificate-authority="$(cat ${WORKING_DIR}/hub-ca.crt)"
kubectl config --kubeconfig="${BOOTSTRAP_KUBECONFIG}" set-credentials $SA_USER --token="${BOOTSTRAP_SA_TOKEN}"
kubectl config --kubeconfig="${BOOTSTRAP_KUBECONFIG}" set-context "${HUB_CLUSTER_NICKNAME}/${SA_USER}" \
    --user="${SA_USER}" \
    --namespace="${CLUSTER_NAME}" \
    --cluster="${HUB_CLUSTER_NICKNAME}"
kubectl config --kubeconfig="${BOOTSTRAP_KUBECONFIG}" use-context "${HUB_CLUSTER_NICKNAME}/${SA_USER}"

echo "--- # ${BOOTSTRAP_KUBECONFIG}"
cat ${BOOTSTRAP_KUBECONFIG}

# Prepare the authorization to apply the Klusterlet on the provisioned cluster
CLUSTER_KUBECONFIG=${WORKING_DIR}/${CLUSTER_NAME}.kubeconfig
touch "${CLUSTER_KUBECONFIG}"

USERNAME=$(oc get secrets ${CLUSTER_NAME} -ogo-template="{{ .data.username|base64decode }}")
PASSWORD=$(oc get secrets ${CLUSTER_NAME} -ogo-template="{{ .data.password|base64decode }}")
API_URL=$(oc get secrets ${CLUSTER_NAME} -ogo-template="{{ .data.api_url|base64decode }}")

# Need to pull the public certificate for the remote cluster; this is insecure
echo "Logging IN: KUBECONFIG=${CLUSTER_KUBECONFIG} oc login -u ${USERNAME} -p ${PASSWORD} --insecure-skip-tls-verify=true ${API_URL}"
KUBECONFIG=${CLUSTER_KUBECONFIG} oc login -u ${USERNAME} -p ${PASSWORD} --insecure-skip-tls-verify=true ${API_URL}

echo "--- # ${CLUSTER_KUBECONFIG}"
cat ${CLUSTER_KUBECONFIG}

# Deploy the Klusterlet operator + Klusterlet configuration
echo "Deploying Klusterlet Operator on ${CLUSTER_NAME}"
kubectl create --kubeconfig="${CLUSTER_KUBECONFIG}" namespace open-cluster-management-agent
kubectl create --kubeconfig="${CLUSTER_KUBECONFIG}"  -f klusterlet-operator.yaml
sleep 5

kubectl apply --kubeconfig="${CLUSTER_KUBECONFIG}"  -f ${WORKING_DIR}/klusterlet.yaml
kubectl delete --kubeconfig="${CLUSTER_KUBECONFIG}" secret  bootstrap-hub-kubeconfig \
        -n open-cluster-management-agent
kubectl create --kubeconfig="${CLUSTER_KUBECONFIG}" secret generic bootstrap-hub-kubeconfig \
    -n open-cluster-management-agent --from-file=kubeconfig="${BOOTSTRAP_KUBECONFIG}"

popd