#!/bin/bash

# Install gcloud
if ! command -v gcloud &> /dev/null
then
    echo "gcloud could not be found, installing..."
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo apt-get update && sudo apt-get install google-cloud-sdk
fi

# Authenticate gcloud
echo "Authenticating gcloud with service account..."
gcloud auth activate-service-account --key-file=[/root/K8/K8/k8project-415716-fd07b3cef25d.json]

# Set gcloud project
gcloud config set project [k8project-415716]

# Install kubectl
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found, installing..."
    sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
fi

# Install helm
if ! command -v helm &> /dev/null
then
    echo "helm could not be found, installing..."
    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
fi

# Add the Kubernetes dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# Update your Helm repositories
helm repo update

# Install the Kubernetes dashboard Helm chart
helm install my-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kube-system --set service.type=NodePort

# Create a Service Account and Cluster Role Binding
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

# Get token
echo "Dashboard Token:"
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

# Get IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
NODE_PORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services my-dashboard -n kube-system)
echo "Dashboard URL: http://$NODE_IP:$NODE_PORT"