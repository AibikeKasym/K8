#!/bin/bash
# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "gcloud could not be found. Installing..."
    # Download the Google Cloud SDK install script
    curl https://sdk.cloud.google.com > install.sh
    # Make the install script executable
    chmod +x install.sh
    # Run the install script
    ./install.sh --disable-prompts
    # Add gcloud to the PATH
    source '/root/Day1/google-cloud-sdk/path.bash.inc'
    # Remove the install script
    rm install.sh
    echo "gcloud installed successfully."
else
    echo "gcloud is already installed."
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Installing..."
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    # Make it executable
    chmod +x ./kubectl
    # Move it to your local bin
    sudo mv ./kubectl /usr/local/bin/kubectl
    echo "kubectl installed successfully."
else
    echo "kubectl is already installed."
fi

# Authenticate to your GCP account
gcloud auth login

# Set the project ID to the one where your GKE cluster resides
gcloud config set project k8project-415716

# Get authentication credentials for the cluster
gcloud container clusters get-credentials my-gke-cluster --zone us-east1-c

# Create a service account for the dashboard
kubectl create serviceaccount dashboard-admin-sa

# Bind the dashboard-admin-sa service account to the cluster-admin role
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa

# Get the token and print it
secret=$(kubectl get serviceaccount dashboard-admin-sa -o jsonpath="{.secrets[0].name}")
kubectl get secret $secret -o jsonpath="{.data.token}" | base64 --decode