#!/bin/bash

function delete_federation() {
    local context=$1
    local project_prefix=$2

    oc config use-context $context
    oc delete project $project_prefix-mesh
    oc delete project $project_prefix-bookinfo
    oc delete -f ./ossm-operator/ossm.yaml
}

delete_federation "rosa" "rosa-prod"
delete_federation "aro" "aro-stg"
delete_federation "rog" "gcp-dev"

echo "If you want to delete the operators, run the following command:"
echo "oc delete csv <csv-name>"
