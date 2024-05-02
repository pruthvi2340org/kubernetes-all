# Capsule is the Open-source tool used for Multi-tenant provide isolation across teams or environments 

Capsule takes a different approach.
In a single cluster,
the Capsule Controller aggregates multiple namespaces in a lightweight abstraction called Tenant,
basically a grouping of Kubernetes Namespaces.
Within each tenant,
users are free to create their namespaces and share all the assigned resources.

**Network and Security Policies, Resource Quota, Limit Ranges, RBAC, and other policies defined at the tenant level are automatically inherited by all the namespaces in the tenant.**

![image](https://github.com/Pruthvi2340/kubernetes-all/assets/152501425/f5317389-bccd-4d36-ab1d-cd8dfe1ee37a)


# Tutorial starts
**Bill creates a new tenant oil in the CaaS management portal according to the tenant's profile:**
```
kubectl create -f - << EOF
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: oil
spec:
  owners:
  - name: alice
    kind: User
EOF

kubectl get tenant oil
```
# Permissions check
```
kubectl auth can-i create namespaces # Should be 'Yes'

kubectl auth can-i delete ns -n oil-production # Should be 'Yes'

kubectl auth can-i get namespaces # Should be 'no'

kubectl auth can-i get nodes  # Should be 'no'

kubectl auth can-i get persistentvolumes  # Should be 'no'

kubectl auth can-i get tenants  # Should be 'no'

```

# Group of users as tenant owner
```
kubectl apply -f - << EOF
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: oil
spec:
  owners:
  - name: alice
    kind: User
  - name: bob
    kind: User
EOF
```
# identity management system and then he assigns Alice and Bob identities to the oil-users group.

The tenant manifest is modified as in the following:
```
kubectl apply -f - << EOF
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: oil
spec:
  owners:
  - name: oil-users
    kind: Group
EOF

kubectl auth can-i create namespaces # should be no
```

