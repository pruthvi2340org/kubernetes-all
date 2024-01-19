#!/bin/bash

git clone https://github.com/nginxinc/kubernetes-ingress.git --branch release-3.4


cd kubernetes-ingress

# Create a namespace and a service account:

kubectl apply -f deployments/common/ns-and-sa.yaml

# Create a cluster role and binding for the service account:

kubectl apply -f deployments/rbac/rbac.yaml


# Create a ConfigMap to customize your NGINX settings:

kubectl apply -f deployments/common/nginx-config.yaml

# Create an IngressClass resource. NGINX Ingress Controller won’t start without an IngressClass resource.

kubectl apply -f deployments/common/ingress-class.yaml


# Core custom resource definitions

kubectl apply -f config/crd/bases/k8s.nginx.org_virtualservers.yaml
kubectl apply -f config/crd/bases/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f config/crd/bases/k8s.nginx.org_transportservers.yaml
kubectl apply -f config/crd/bases/k8s.nginx.org_policies.yaml
kubectl apply -f config/crd/bases/k8s.nginx.org_globalconfigurations.yaml



# Optional custom resource definitions

# For the NGINX App Protect WAF module, create CRDs for APPolicy, APLogConf and APUserSig:

kubectl apply -f config/crd/bases/appprotect.f5.com_aplogconfs.yaml
kubectl apply -f config/crd/bases/appprotect.f5.com_appolicies.yaml
kubectl apply -f config/crd/bases/appprotect.f5.com_apusersigs.yaml

# For the NGINX App Protect DoS module, create CRDs for APDosPolicy, APDosLogConf and DosProtectedResource:

kubectl apply -f config/crd/bases/appprotectdos.f5.com_apdoslogconfs.yaml
kubectl apply -f config/crd/bases/appprotectdos.f5.com_apdospolicy.yaml
kubectl apply -f config/crd/bases/appprotectdos.f5.com_dosprotectedresources.yaml

# Deploy NGINX Ingress Controller

# Using deployment method

kubectl apply -f deployments/deployment/nginx-ingress.yaml
