resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "kubernetes_engine_api" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
  
  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudresourcemanager_api,
    google_project_service.kubernetes_engine_api
  ]
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.self_link

  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudresourcemanager_api,
    google_project_service.kubernetes_engine_api
  ]
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnetwork"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.self_link

  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudresourcemanager_api,
    google_project_service.kubernetes_engine_api
  ]
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.public_subnet.self_link

  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudresourcemanager_api,
    google_project_service.kubernetes_engine_api
  ]

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${self.name} --region ${self.location}"
  }
}


resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [
    google_project_service.compute_api,
    google_project_service.cloudresourcemanager_api,
    google_project_service.kubernetes_engine_api
  ]
}

output "cluster_endpoint" {
  description = "The IP address of the Kubernetes master."
  value       = google_container_cluster.primary.endpoint
}

resource "null_resource" "execute_script" {
  depends_on = [google_container_node_pool.primary_preemptible_nodes]

  provisioner "local-exec" {
    command = "/root/K8/K8/setup.sh"
  }
}
