oc config use-context rosa
oc apply -f ossm-operator/ossm.yaml
oc config use-context aro
oc apply -f ossm-operator/ossm.yaml
oc config use-context rog
oc apply -f ossm-operator/ossm.yaml
