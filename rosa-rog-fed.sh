#!/bin/bash

set -e

log() {
  echo "##############"
  echo "##### $*"
  echo "###############"
}

# log "Creating projects for ROSA"
# oc config use-context rosa
# oc new-project rosa-prod-mesh || true
# oc new-project prod-bookinfo || true

# log "Installing control plane for rosa-prod-mesh"
# oc apply -f rosa-prod/smcp.yaml
# oc apply -f rosa-prod/smmr.yaml

# change to submariner 2 context
oc config use-context rog

log "Creating projects for gcp-dev-mesh"
oc new-project gcp-dev-mesh || true
oc new-project dev-bookinfo || true

log "Installing control plane for gcp-dev-mesh"
oc apply -f gcp-dev/smcp.yaml
oc apply -f gcp-dev/smmr.yaml

oc config use-context rosa
log "Waiting for rosa-prod-mesh installation to complete"
oc wait --for condition=Ready -n rosa-prod-mesh smmr/default --timeout 300s
oc config use-context rog
log "Waiting for gcp-dev-mesh installation to complete"
oc wait --for condition=Ready -n gcp-dev-mesh smmr/default --timeout 300s

log "Installing details v3 service in gcp-dev-mesh"
oc apply  -f gcp-dev/dev-detail-v3-deployment.yaml
oc apply  -f gcp-dev/dev-detail-v3-service.yaml



oc config use-context rosa
# log "Installing bookinfo application in rosa-prod-mesh"
# oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/platform/kube/bookinfo.yaml
# oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/bookinfo-gateway.yaml
# oc apply -n prod-bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.0/samples/bookinfo/networking/destination-rule-all.yaml

log "Retrieving Istio CA Root certificates"
ROSA_PROD_MESH_CERT=$(oc get configmap -n rosa-prod-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
#PROD_MESH_CERT=$(echo "$PROD_MESH_CERT" | tr -d '\n')

oc config use-context rog
GCP_DEV_MESH_CERT=$(oc get configmap -n gcp-dev-mesh istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | sed ':a;N;$!ba;s/\n/\\\n    /g')
#STAGE_MESH_CERT=$(echo "$STAGE_MESH_CERT" | tr -d '\n')

oc config use-context rosa
log "Enabling federation for rosa-prod-mesh"
sed "s:{{GCP_DEV_MESH_CERT}}:$GCP_DEV_MESH_CERT:g" rosa-prod/gcp-dev-mesh-ca-root-cert.yaml | oc apply -f -
oc apply -f rosa-prod/smp-gcp.yaml
oc apply -f rosa-prod/iss-gcp.yaml

oc config use-context rog
log "Enabling federation for gcp-dev-mesh"
sed "s:{{ROSA_PROD_MESH_CERT}}:$ROSA_PROD_MESH_CERT:g" gcp-dev/rosa-prod-mesh-ca-root-cert.yaml | oc apply -f -
oc apply -f gcp-dev/smp.yaml
oc apply -f gcp-dev/ess.yaml


oc config use-context rosa
log "Installing VirtualService for rosa-prod-mesh"
oc apply -n prod-bookinfo -f rosa-prod/vs-split-details-prod-stg-dev.yaml
# oc apply -f rosa-prod-mesh/vs-split-details.yaml

log 'INSTALLATION COMPLETE

Run the following command in the rosa-prod-mesh to check the connection status:

  oc -n rosa-prod-mesh get servicemeshpeer gcp-dev-mesh -o json | jq .status

Run the following command to check the connection status in gcp-dev-mesh:

  oc -n gcp-dev-mesh get servicemeshpeer rosa-prod-mesh -o json | jq .status

Check if services from gcp-dev-mesh are imported into rosa-prod-mesh:

  oc -n rosa-prod-mesh get importedservicesets gcp-dev-mesh -o json | jq .status

Check if services from gcp-dev-mesh are exported:

  oc -n gcp-dev-mesh get exportedservicesets rosa-prod-mesh -o json | jq .status

To see federation in action, create some load in the bookinfo app in rosa-prod-mesh. For example:

  BOOKINFO_URL=$(oc -n rosa-prod-mesh get route istio-ingressgateway -o json | jq -r .spec.host)
  while true; do sleep 1; curl http://${BOOKINFO_URL}/productpage &> /dev/null; done

'
