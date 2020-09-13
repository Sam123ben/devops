.DEFAULT_GOAL:= help

# export NEED_TO_ASSUME_ROLE ?= true

help: 
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.SILENT:

login: ## Login to the azure subscription to be able to access and create the resoruces via automation: make login
	az login

delete-all: ## Provison azure resources only: make delete-all
	scripts/provision-delete-resources.sh

provision-aks: ## Provison azure resources only: make provision-aks
	scripts/provision.sh

.PHONY:
	login
