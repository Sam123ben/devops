#!/usr/bin/env bash
set -e
set -eou pipefail

echo -e "\n########################################################\n"
echo -e "#### EXECUTING THE PLATFORM RESOURCES DELETION TASK ####\n"
echo -e "##########################################################\n"

platformPath="../../terraform"
scriptPath="./terraform"

# include parse_yaml function
. scripts/lib/parse_yaml.sh

PLATFORM_FOLDER=$1
DR_ENABLE=$2
PROD_ENABLE=$3

export ANSIBLE_CONFIG="./ansible.cfg"

eval $(parse_yaml values/variables.yaml "config_")
eval $(parse_yaml ./ansible/tasks/vars/all.yml "all_")

echo -e "\naz account set -s '$config_subscription_id'\n"

az account set -s "$config_subscription_id"

echo -e "\n#################################################################\n"
echo -e "#### EXECUTING THE AZURE VNET DELETION OF THE SUBDOMAIN ####\n"
echo -e "###################################################################\n"
cd $scriptPath/$config_location/aks/vnet

terraform destroy -auto-approve
cd -

echo -e "\n###############################################################\n"
echo -e "#### EXECUTING THE AZURE SUBNET DELETION OF THE AKS CLUSTER ####\n"
echo -e "#################################################################\n"
cd $scriptPath/$config_location/aks/subnet

terraform destroy -auto-approve
cd -

echo -e "\n#####################################################################\n"
echo -e "#### EXECUTING THE AZURE AKS CLUSTER DELETION OF MsSQL DB SERVER ####\n"
echo -e "#######################################################################\n"

cd $scriptPath/$config_location/akscluster
terraform destroy -auto-approve

cd -