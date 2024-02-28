# Here's a breakdown of what this script does:


# Enable the necessary APIs: The google_project_service resources enable the necessary APIs (compute.googleapis.com, cloudresourcemanager.googleapis.com, and container.googleapis.com) for the project specified by var.project_id.

# Create a VPC network: The google_compute_network resource creates a Virtual Private Cloud (VPC) network named my-vpc with no auto-created subnetworks.

# Create subnetworks: The google_compute_subnetwork resources create two subnetworks, public-subnet and private-subnetwork, with the specified IP CIDR ranges in the region specified by var.region.

# Create a GKE cluster: The google_container_cluster resource creates a GKE cluster named my-gke-cluster in the zone specified by var.zone, with the previously created VPC network and public subnet. It also removes the default node pool and disables the issuance of client certificates for authentication.

# Create a node pool: The google_container_node_pool resource creates a node pool named my-node-pool for the GKE cluster, with one preemptible n1-standard-1 VM instance.

# Output the cluster endpoint: The output block prints the IP address of the Kubernetes master.

# Set up the cluster: The null_resource with the local-exec provisioner named execute_setup runs a local shell script named setup.sh to set up the cluster. This script must exist in your local directory and needs to be executable.

# Deploy the Kubernetes Dashboard: The null_resource with the local-exec provisioner named deploy_dashboard applies the Kubernetes Dashboard deployment YAML from the official GitHub repository.
