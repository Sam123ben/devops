#!/usr/bin/env bash
set -e
set +x # set -x for debugging the logs
set -eou pipefail

echo -e "\n################################################################\n"
echo -e "#### EXECUTING THE PLATFORM AZURE ROLES OF PLAYBOOK TASK  ####\n"
echo -e "##################################################################\n"

platformPath="../../terraform"
scriptPath="./terraform"

# include parse_yaml function
. scripts/lib/parse_yaml.sh

export ANSIBLE_CONFIG="./ansible.cfg"

eval $(parse_yaml values/variables.yaml "config_")
eval $(parse_yaml ./ansible/tasks/vars/all.yml "all_")

echo -e "\naz account set -s '$config_subscription_id'\n"

az account set -s "$config_subscription_id"

echo -e "\n##################################################################\n"
echo -e "#### EXECUTING THE AKS VNET PROVISION TERRAFORM ####\n"
echo -e "####################################################################\n"

mkdir -p $scriptPath/$config_location

ansible-playbook -e platform_folder=$platformPath \
    -e location=$config_location \
    ansible/tasks/provision-aks-vnet-platform.yml

cd $scriptPath/$config_location/aks/vnet

terraform init -no-color -lock=true -get=true -force-copy
terraform apply -no-color -input=false -auto-approve=true
cd -

echo -e "\n##################################################################\n"
echo -e "#### EXECUTING THE AKS SUBNET PROVISION TERRAFORM ####\n"
echo -e "####################################################################\n"

cd $scriptPath/$config_location/aks/subnet

terraform init -no-color -lock=true -get=true -force-copy
terraform apply -no-color -input=false -auto-approve=true
cd -

echo -e "\n\n######## CREATION IN PROGRESS FOR AKS CLUSTER #########\n\n"

echo -e "\n###########################################################\n"
echo -e "#### EXECUTING THE AKS CLUSTER PROVISION TERRAFORM ####\n"
echo -e "##############################################################\n"

echo -e "\naz account set -s '$config_subscription_id'\n"

mkdir -p $scriptPath/$config_location/akscluster/
mkdir -p $scriptPath/$config_location/ssh_keys

ansible-playbook -e platform_folder=$platformPath \
    -e version=$all_k8sversion \
    -e location=$config_location \
    ansible/tasks/create-aks-cluster.yml

cd $scriptPath/$config_location/akscluster

terraform init -no-color -lock=true -get=true -force-copy
terraform apply -no-color -input=false -auto-approve=true

cd -

# echo -e "\n\naz aks enable-addons -a monitoring -n $config_name-$config_location-aks -g $config_rgname\n\n"

# az aks enable-addons -a monitoring -n $config_name-$config_location-aks -g $config_rgname || true

echo -e "\n#######  THE AKS CLUSTER OF $all_k8sversion VERSION OF PRODUCTION AKS IS CREATED AND THE RELATED KUBECONFIG FILE IS GENERATED   #######\n"

echo -e "\n#######  THE AKS CLUSTER OF $all_k8sversion VERSION WILL NOW BE CONFIGURED AND THE RELATED UTILITIES WILL BE INSTALLED   #######\n"

echo -e "\naz aks get-credentials --resource-group $config_rgname --name $config_name-$config_location-aks"

az aks get-credentials --resource-group $config_rgname --name $config_name-$config_location-aks --overwrite-existing

export KUBECONFIG=$HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml

if [[ "$config_letsencrypt_type" == "prod" ]]
then
    echo -e "\nThe lets encrypt issuer type is prod... \n"
    letsencrypt_url="https://acme-v02.api.letsencrypt.org/directory"
    letsencrypt_type="prod"
    sleep 3s
else
    echo -e "\nThe lets encrypt issuer type is stage... \n"
    letsencrypt_url="https://acme-staging-v02.api.letsencrypt.org/directory"
    letsencrypt_type="stage"
    sleep 3s
fi

echo -e "####\n## Installing the envs related to the cluster\n####"

echo -e "####\n##  creating the env namespace to host all the cluster related apps or tools\n####"

kubectl apply -f https://bit.ly/k4k8s -n kong

helm repo add kong https://charts.konghq.com
helm repo update

helm install kong/kong --generate-name --set ingressController.installCRDs=false --namespace kong

sleep 15s

echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: request-id
config:
  header_name: my-request-id
plugin: correlation-id
" | kubectl apply -f -

echo "
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: rl-by-ip
config:
  minute: 5
  limit_by: ip
  policy: local
plugin: rate-limiting
" | kubectl apply -f -

kubectl create ns dev || true

#kubectl config set-context --current --namespace=dev

kubectl apply -f http://bit.ly/bookinfoapp -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/details-v1 -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/productpage-v1 -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/ratings-v1 -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/reviews-v1 -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/reviews-v2 -n dev
echo -e "\n\n"
kubectl rollout status -w deployment/reviews-v3 -n dev

echo -e "\n\n"

echo "
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
    name: do-not-preserve-host
route:
  preserve_host: false
upstream:
  host_header: productpage.default.svc
" | kubectl apply -f -

echo -e "\n\n"

kubectl annotate service productpage ingress.kubernetes.io/service-upstream="true" --overwrite -n dev
kubectl patch svc productpage -p '{"metadata":{"annotations":{"konghq.com/plugins": "rl-by-ip\n"}}}'

echo -e "\n\n"

kubectl exec -it $(kubectl get pod -n dev -l app=ratings -o jsonpath='{.items[0].metadata.name}') -n dev -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"

echo -e "\n\n"

echo "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: productpage
  annotations:
    configuration.konghq.com: do-not-preserve-host
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: productpage
          servicePort: 9080
" | kubectl apply -n dev -f -

ingressIp=$(kubectl get ingress -n dev --namespace dev -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')

echo -e "\nIF THE BELOW CURL WORKED THEN IT MEANS YOU ARE ALL DONE AND IT IS WORKING AS EXPECTED\n"
curl -i -H "Host: *" $ingressIp