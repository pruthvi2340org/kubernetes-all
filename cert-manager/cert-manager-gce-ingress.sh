#!/bin/bash

# Create namespace for Cert-Manager
kubectl create namespace cert-manager

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml

# Wait for cert-manager components to be deployed
kubectl wait --timeout=300s --for=condition=Available deployment --all -n cert-manager

# Create a ClusterIssuer (change this based on your certificate provider)
cat <<EOF | kubectl apply -f -
# issuer-lets-encrypt-production.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: pruthvi990038@gmail.com # ❗ Replace this with your email address
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          name: web-ingress
EOF

gcloud compute addresses create web-ip --global
kubectl create ns hello-app
kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0 -n hello-app
kubectl expose deployment web --port=8080 -n hello-app

# Create an example Ingress with a TLS certificate using Nginx Ingress class
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: web-ssl
  namespace: hello-app
type: kubernetes.io/tls
stringData:
  tls.key: ""
  tls.crt: ""
EOF

# Create an example Ingress with a TLS certificate using Nginx Ingress class
cat <<EOF | kubectl apply -f -
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: hello-app
  annotations:
    # This tells Google Cloud to create an External Load Balancer to realize this Ingress
    kubernetes.io/ingress.class: gce
    # This enables HTTP connections from Internet clients
    kubernetes.io/ingress.allow-http: "true"
    # This tells Google Cloud to associate the External Load Balancer with the static IP which we created earlier
    kubernetes.io/ingress.global-static-ip-name: web-ip
spec:
  tls:
    - secretName: web-ssl
      hosts:
        - cert-test.pruthvi.org
  defaultBackend:
    service:
      name: web
      port:
        number: 8080
  # This section is only required if TLS is to be enabled for the Ingress
  tls:
    - secretName: web-ssl
      hosts:
      - retail.pruthvi.org
EOF

# Monitor the Certificate resource for certificate issuance
kubectl get pods -n cert-manager
kubectl describe clusterissuers.cert-manager.io letsencrypt-production #letsencrypt-staging
kubectl get certificate --all-namespaces
kubectl describe ingress web-ingress -n hello-app
kubectl get secret -n hello-app
kubectl get certificates -n default --watch
