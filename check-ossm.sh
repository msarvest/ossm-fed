
clusters=("rosa" "aro" "rog")
subscriptions=("elasticsearch-operator" "jaeger-product" "kiali-ossm" "servicemeshoperator")

for context in "${clusters[@]}"; do
    oc config use-context "$context"
    echo "***************************************************************************"
    echo "Checking $context cluster, you should see all available catalogsources are healthy for all operators"
    echo "***************************************************************************"
    for sub in "${subscriptions[@]}"; do
        echo -e "\n\n**** Checking $sub operator status  ***"
        oc get sub "$sub" -n openshift-operators --output jsonpath='{.status.conditions[?(@.type=="CatalogSourcesUnhealthy")].message}'
    done
    echo -e "\n"
done

