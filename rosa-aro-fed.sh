#!/bin/bash

set -e

log() {
  echo "##############"
  echo "##### $*"
  echo "###############"
}

log "Creating projects for ROSA"
oc config use-context rosa
oc new-project rosa-prod-mesh || true
oc new-project prod-bookinfo || true

log "Installing control plane for rosa-prod-mesh"
oc apply -f rosa-prod/smcp.yaml
oc apply -f rosa-prod/smmr.yaml

# change to aro context
oc config use-context aro

log "Creating projects for aro-stg-mesh"
oc new-project aro-stg-mesh || true
oc new-project stg-bookinfo || true

log "Installing control plane for aro-stg-mesh"
oc apply -f aro-stg/smcp.yaml
oc apply -f aro-stg/smmr.yaml

oc config use-context rosa
log "Waiting for rosa-prod-mesh installation to complete"
oc wait --for condition=Ready -n rosa-prod-mesh smmr/default --timeout 300s
oc config use-context aro
log "Waiting for aro-stg-mesh installation to complete"
oc wait --for condition=Ready -n aro-stg-mesh smmr/default --timeout 300s

log "Installing details v2 service in aro-stg-mesh"
oc apply  -f aro-stg/stage-detail-v2-deployment.yaml
oc apply  -f aro-stg/stage-detail-v2-service.yaml



oc config use-context rosa
log "Installing bookinfo application in rosa-prod-mesh"
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml

log "Retrieving Istio CA Root certificates"
#ROSA_PROD_MESH_CERT=$(oc get configmap -n rosa-prod-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
#PROD_MESH_CERT=$(echo "$PROD_MESH_CERT" | tr -d '\n')
ROSA_PROD_MESH_CERT=$(oc get configmap -n rosa-prod-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}')

oc config use-context aro
#ARO_STG_MESH_CERT=$(oc get configmap -n aro-stg-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
ARO_STG_MESH_CERT=$(oc get configmap -n aro-stg-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}')
#STAGE_MESH_CERT=$(echo "$STAGE_MESH_CERT" | tr -d '\n')

oc config use-context rosa
log "Enabling federation for rosa-prod-mesh"
#sed "s:{{ARO_STG_MESH_CERT}}:$ARO_STG_MESH_CERT:g" rosa-prod/aro-stg-mesh-ca-root-cert.yaml | oc apply -f -
oc create configmap aro-stg-mesh-ca-root-cert --from-literal=root-cert.pem="$ARO_STG_MESH_CERT" -n rosa-prod-mesh

oc apply -f rosa-prod/smp-aro.yaml
oc apply -f rosa-prod/iss-aro.yaml

oc config use-context aro
log "Enabling federation for aro-stg-mesh"
#sed "s:{{ROSA_PROD_MESH_CERT}}:$ROSA_PROD_MESH_CERT:g" aro-stg/rosa-prod-mesh-ca-root-cert.yaml | oc apply -f -
oc create configmap rosa-prod-mesh-ca-root-cert  --from-literal=root-cert.pem="$ROSA_PROD_MESH_CERT" -n aro-stg-mesh
oc apply -f aro-stg/smp.yaml
oc apply -f aro-stg/ess.yaml


oc config use-context rosa
log "Installing VirtualService for rosa-prod-mesh"
oc apply -n prod-bookinfo -f rosa-prod/vs-mirror-details.yaml
# oc apply -f rosa-prod-mesh/vs-split-details.yaml

log 'INSTALLATION COMPLETE

Run the following command in the rosa-prod-mesh to check the connection status:

  oc -n rosa-prod-mesh get servicemeshpeer aro-stg-mesh -o json | jq .status

Run the following command to check the connection status in aro-stg-mesh:

  oc -n aro-stg-mesh get servicemeshpeer rosa-prod-mesh -o json | jq .status

Check if services from aro-stg-mesh are imported into rosa-prod-mesh:

  oc -n rosa-prod-mesh get importedservicesets aro-stg-mesh -o json | jq .status

Check if services from aro-stg-mesh are exported:

  oc -n aro-stg-mesh get exportedservicesets rosa-prod-mesh -o json | jq .status

To see federation in action, create some load in the bookinfo app in rosa-prod-mesh. For example:

  BOOKINFO_URL=$(oc -n rosa-prod-mesh get route istio-ingressgateway -o json | jq -r .spec.host)
  while true; do sleep 1; curl http://${BOOKINFO_URL}/productpage &> /dev/null; done

'
