

########################################################
add the following content after   Note: All the scripts utilize three kubeconfig contexts, each with a specific purpose:

you need to rename context for each cluster with the following command

```bash
oc config get-contexts
oc config use-context <rosa's cluster context>
oc config rename-context  <rosa's cluster context> rosa
oc config use-context <aro's cluster context>
oc config rename-context  <aro's cluster context> aro
oc config use-context <rog's cluster context>
oc config rename-context  <rog's cluster context> rog
```

########################################################
Git clone https://github.com/houshym/ossm-fed.git
to
git clone https://github.com/houshym/ossm-fed.git
cd ossm-fed
cd ossm-fed
**NOTE:** use the git repo for the latest update
########################################################




oc get sub elasticsearch-operator -n openshift-operators --output jsonpath='{.status.conditions[*].message}'
oc get sub jaeger-product  -n openshift-operators --output jsonpath='{.status.conditions[*].message}'
oc get sub kiali-ossm  -n openshift-operators --output jsonpath='{.status.conditions[*].message}'
oc get sub servicemeshoperator -n openshift-operators --output jsonpath='{.status.conditions[*].

########################################################
echo $ROSA_PROD_MESH_CERT | openssl x509 -subject -noout
to
echo "$ROSA_PROD_MESH_CERT" | openssl x509 -subject -noout

########################################################
echo $ARO_STG_MESH_CERT | openssl x509 -subject -noout
to
echo "$ARO_STG_MESH_CERT" | openssl x509 -subject -noout

########################################################
echo $ROSA_PROD_MESH_CERT | openssl x509 -subject -noout
to 
echo "$ROSA_PROD_MESH_CERT" | openssl x509 -subject -noout

########################################################

echo $GCP_DEV_MESH_CERT | openssl x509 -subject -noout
to 
echo "$GCP_DEV_MESH_CERT" | openssl x509 -subject -noout

########################################################

echo $SMP_ARO_YAML | oc apply -f -
to 
echo "$SMP_ARO_YAML" | oc apply -f -

echo $SMP_PROD_YAML | oc apply -f -
to
echo "$SMP_PROD_YAML" | oc apply -f -

########################################################

echo $SMP_ROG_YAML | oc apply -f -
    oc apply -f gcp-dev/smp.yaml
to
echo "$SMP_ROG_YAML" | oc apply -f -
    oc apply -f gcp-dev/smp.yaml

########################################################

echo $SMP_ROSA_ROG_YAML | oc apply -f -
    oc apply -f rosa-prod/iss-gcp.yaml
to 
echo "$SMP_ROSA_ROG_YAML" | oc apply -f -
    oc apply -f rosa-prod/iss-gcp.yaml

########################################################


export ARO_STG_INGRESS=$(oc get svc rosa-prod-ingress -n aro-stg-mesh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
to 
export ARO_STG_INGRESS=$(oc get svc rosa-prod-ingress -n aro-stg-mesh -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

########################################################

export ROG_DEV_INGRESS=$(oc get svc gcp-dev-ingress -n rosa-prod-mesh -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
to
export ROG_DEV_INGRESS=$(oc get svc gcp-dev-ingress -n rosa-prod-mesh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')


########################################################

Check connection status on aro-stg-mesh 
to 
Check federation status on aro-stg-mesh

########################################################

SMP_ROG_YAML=$(cat gcp-dev/smp.yaml | sed "s/rosa-prod-ingress-url/$ROSA_DEV_INGRESS/g")
to
SMP_ROG_YAML=$(cat gcp-dev/smp.yaml | sed "s/rosa-prod-ingress-url/$ROG_DEV_INGRESS/g")

########################################################

export ROG_ROSA_PROD_INGRESS=$(oc get svc rosa-prod-ingress -n gcp-dev-mesh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
to 
export ROG_ROSA_PROD_INGRESS=$(oc get svc rosa-prod-ingress -n gcp-dev-mesh -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $ROG_ROSA_PROD_INGRESS

########################################################

SMP_ROSA_ROG_YAML=(cat /rosa-prod/smp-gcp.yaml | sed "s/gcp-dev-ingress-url/$ROG_ROSA_PROD_INGRESS/g")
to
SMP_ROSA_ROG_YAML=$(cat rosa-prod/smp-gcp.yaml | sed "s/gcp-dev-ingress-url/$ROG_ROSA_PROD_INGRESS/g")

*** please pay attention to change /rosa-prod and change it to rosa-prod
########################################################



 cat << EOF | oc apply -f -
 apiVersion: v1
 kind: Namespace
 metadata:
 name: openshift-operators-redhat
 ---
 apiVersion: v1
 kind: Namespace
 metadata:
 name: openshift-distributed-tracing
 ---
 # installing elastic search operator
 #Create a Subscription to subscribe the openshift-operators namespace 
 # to the OpenShift Elasticsearch Operator
 apiVersion: operators.coreos.com/v1alpha1
 kind: Subscription
 metadata:
 name: elasticsearch-operator
 namespace: openshift-operators
 spec:
 channel: "stable"
 name: elasticsearch-operator
 source: redhat-operators
 sourceNamespace: openshift-marketplace
 installPlanApproval: Automatic
 ---
 #install jaeger operator
 apiVersion: operators.coreos.com/v1alpha1
 kind: Subscription
 metadata:
 name: jaeger-product
 namespace: openshift-operators
 spec:
 name: jaeger-product
 source: redhat-operators
 sourceNamespace: openshift-marketplace
 channel: "stable"
 installPlanApproval: Automatic
 --- 
 #install Kiali operator
 apiVersion: operators.coreos.com/v1alpha1
 kind: Subscription
 metadata:
 name: kiali-ossm
 namespace: openshift-operators
 spec:
 name: kiali-ossm
 source: redhat-operators
 sourceNamespace: openshift-marketplace
 channel: "stable"
 installPlanApproval: Automatic
 --- 
 # Create a Subscription to subscribe the openshift-operators
 # namespace to the Red Hat OpenShift Service Mesh Operator
 apiVersion: operators.coreos.com/v1alpha1
 kind: Subscription
 metadata:
 name: servicemeshoperator
 namespace: openshift-operators
 spec:
 channel: "stable"
 name: servicemeshoperator
 source: redhat-operators
 sourceNamespace: openshift-marketplace
 installPlanApproval: Automatic
 EOF