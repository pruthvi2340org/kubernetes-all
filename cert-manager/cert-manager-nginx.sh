#!/bin/bash

# Create namespace for Cert-Manager
kubectl create namespace cert-manager

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml

# Wait for cert-manager components to be deployed
kubectl wait --timeout=300s --for=condition=Available deployment --all -n cert-manager

# Create a ClusterIssuer (change this based on your certificate provider)
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production #letsencrypt-staging
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: pruthvi990038@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production #letsencrypt-staging
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

kubectl create ns hello-world-2

kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0 -n hello-world-2
kubectl expose deployment web --type=NodePort --port=8080 -n hello-world-2
kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0 -n hello-world-2
kubectl expose deployment web2 --port=8080 --type=NodePort -n hello-world-2

# Create an example Ingress with a TLS certificate using Nginx Ingress class
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: web-ssl-1
type: kubernetes.io/tls
stringData:
  tls.key: ""
  tls.crt: ""
EOF

# Create an example Ingress with a TLS certificate using Nginx Ingress class
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: testing-ingress
  namespace: hello-world-2
  annotations: 
    acme.cert-manager.io/http01-ingress-class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
    kubernetes.io/ingress.allow-http: "true"
    kubernetes.io/ingress.global-static-ip-name: retail-demo-app-1
spec:
  ingressClassName: nginx
  rules:
    - host: retail.pruthvi.org
      http:
        paths:
          - pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
            path: /
          - pathType: Prefix
            backend:
              service:
                name: web2
                port:
                  number: 8080
            path: /v2
  # This section is only required if TLS is to be enabled for the Ingress
  tls:
    - secretName: web-ssl-1
      hosts:
      - retail.pruthvi.org
EOF

# Monitor the Certificate resource for certificate issuance
kubectl get pods -n cert-manager
kubectl describe issuers.cert-manager.io letsencrypt-production #letsencrypt-staging
kubectl get certificate --all-namespaces
kubectl describe ingress testing-ingress -n hello-world-2
kubectl get secret -n hello-world-2
