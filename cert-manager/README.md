# ACME SSL Certificate issued by below script

# Prerequisite:

1. This works only on GKE cluster on HTTP loadbalancing Enabled.
2. This works only on the GCP Cloud DNS zone managed Domains.
3. Public zone should be there in the Cloud DNS of GCP.

# Advantages:

1. Many subdomains can be linked to the Same nginx loadbalancer IP.
2. Auto Renewal of SSL certificate can done.

# How it works:

1. It is using letsencrypt staging issur before requesting for letsencrypt production server.
2. It uses http01 challenge to obtain certificate.
3. Nginx ingress is the Challenge solver which given by Acme.

**use below commands:**
```
git clone https://github.com/Pruthvi2340/kubernetes-all.git
chmod 777 kubernetes-all/cert-manager/acme-reusable-issuing-script-for-gke-nginx-ingress.sh
./kubernetes-all/cert-manager/acme-reusable-issuing-script-for-gke-nginx-ingress.sh
```
```
Enter the domain host (e.g., retail.pruthvi.org): demo1.pruthvi.org
Enter the DNS zone (e.g., pruthvi.org): pruthvi-org
Enter the common namespace (e.g., my-common-namespace): demo1
```
