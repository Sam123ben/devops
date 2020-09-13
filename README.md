## devops

## PREREQUISITES TO CONFIGURE THE AKS WITH KONG AND A DEMO APP

1. kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
2. azure cli (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. ansible (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
4. terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)
5. make (brew install make) [install brew in case not installed: https://brew.sh]
6. You can use a service principal with Owner/Contributor role or you can login as yourself if you have the access to create aks and network

Once installed run the below command to setup the aks and the kong and a demo app

git clone https://github.com/Sam123ben/devops.git
cd devops
make login
make provision-aks

## Outcomes of the above
The above commands will create the following below:

1. RESOURCE GROUP
2. VNET
3. SUBNET
4. AKS
5. KONG GATEWAY (CE)
6. A DEMO APP

Once all the above are created and are deployed we can access the sample app using the host:

http://<ingress-ip>/

## Directory Structure as explained:

1. ansible (Used for templating the terraform to be able to create the infra)
2. terraform (Used for automating the infrastructure)
3. scripts (simple bash script to trigger the terraform and kubectl commands)
4. value (A value file where all the proeprties and related values are maintained which will be used by the end users to create the infra)