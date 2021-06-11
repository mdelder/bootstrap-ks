export NAMESPACE=${NAMESPACE:-bootstrap-ks}
oc create secret generic -n $NAMESPACE openshift-pull-secret --from-file=pull-secret.txt=$OCP_PULL_SECRET_FILE
oc create secret generic bootstrap-ks-creds \
    -n $NAMESPACE \
    --from-literal=AZURE_PASS=$AZURE_PASS \
    --from-literal=AZURE_USER=$AZURE_USER \
    --from-literal=AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    --from-literal=TARGET_KS=aro;
oc create secret generic bootstrap-aks-creds \
    -n $NAMESPACE \
    --from-literal=AZURE_PASS=$AZURE_PASS \
    --from-literal=AZURE_USER=$AZURE_USER \
    --from-literal=AZURE_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID \
    --from-literal=TARGET_KS=aks;