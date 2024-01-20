#!/bin/bash

# Default class for nginx
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx-public
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: k8s.io/ingress-nginx
EOF

# ////////// Nginx-controller Installation /////////////////#

kubectl create clusterrolebinding cluster-admin-binding   --clusterrole cluster-admin   --user $(gcloud config get-value account)

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for the external IP to be assigned
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ]; then
        echo "Waiting for external IP assignment..."
        sleep 10
    fi
done

echo "External IP has been assigned: $EXTERNAL_IP"

# Apply Cloud DNS record set
gcloud dns record-sets transaction start --zone=pruthvi-org
gcloud dns record-sets transaction add --zone=pruthvi-org-zone --name=retail.pruthvi.org. --type=A --ttl=300 "$EXTERNAL_IP"
gcloud dns record-sets transaction execute --zone=pruthvi-org


# ////////// Cert-Manager Installation /////////////////#

# Create namespace for Cert-Manager
kubectl create namespace cert-manager

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.1/cert-manager.yaml

# Wait for cert-manager components to be deployed
kubectl wait --timeout=300s --for=condition=Available deployment --all -n cert-manager


# staging certificate issuer in the the default namespace
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: pruthvi990038@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
EOF

# Prod certificate issuer in the the default namespace
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: pruthvi990038@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
EOF

# Sample deployment

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
spec:
  selector:
    matchLabels:
      app: kuard
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - image: gcr.io/kuar-demo/kuard-amd64:1
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 8080
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    cloud.google.com/neg: '{"ingress":true}'
  name: kuard
  namespace: default
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: kuard
  type: ClusterIP
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/issuer: letsencrypt-staging
  name: kuard
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: retail.pruthvi.org
    http:
      paths:
      - backend:
          service:
            name: kuard
            port:
              number: 80
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - retail.pruthvi.org
    secretName: tls-retail-pruthvi-org
EOF

# Monitor the Certificate resource for certificate issuance
kubectl get pods -n cert-manager
kubectl get certificate -n default
kubectl get issuers -n default
kubectl describe certificate tls-retail-pruthvi-org -n default
kubectl describe secret tls-retail-pruthvi-org -n default
kubectl describe ingress kuard -n default
kubectl get secret -n default

# Wait until the certificate is in the "True" state
while [ "$(kubectl get certificate tls-retail-pruthvi-org -n default -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
    echo "Waiting for the certificate to be ready..."
    sleep 10
done

echo "Certificate is ready. Proceeding with the overwrite annotation."

# Apply overwrite annotation
kubectl annotate ingress kuard cert-manager.io/issuer=letsencrypt-prod --overwrite -n default

# Delete the secret (if needed)
kubectl delete secret tls-retail-pruthvi-org -n default

# Wait until the certificate is in the "True" state after deleting the secret
while [ "$(kubectl get certificate tls-retail-pruthvi-org -n default -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != "True" ]; do
    echo "Waiting for the certificate to be ready after deleting the secret..."
    sleep 10
done

# Beautified message
echo "====================================="
echo "  SSL Certificate Issued by Let's Encrypt"
echo "====================================="
echo "Ready for use!"
echo
