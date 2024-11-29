terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = "jaguer-park-champion-demo"
  region  = "asia-northeast1"
}

data "google_project" "main" {
}

resource "google_artifact_registry_repository" "main" {
  location      = "asia-northeast1"
  repository_id = "jaguer-winter"
  format        = "DOCKER"
}

resource "google_compute_address" "ip_address" {
  name = "mediamtx"
}

resource "google_compute_network" "main" {
  name                    = "jaguer-winter"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "jaguer-winter-tokyo"
  ip_cidr_range = "192.168.0.0/24"
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.0.0.0/16"
  }
  secondary_ip_range {
    range_name    = "svc"
    ip_cidr_range = "10.1.0.0/16"
  }
}

resource "google_compute_firewall" "default" {
  name    = "allow-ingress-mediamtx"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["1935", "8554"]
  }

  source_ranges = [
    "0.0.0.0/0"
  ]

  disabled = true
}

resource "google_container_cluster" "main" {
  name = "jaguer-winter"

  enable_autopilot = true
  network          = google_compute_network.main.id
  subnetwork       = google_compute_subnetwork.main.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod"
    services_secondary_range_name = "svc"
  }
}

resource "google_project_iam_binding" "main" {
  project = data.google_project.main.project_id
  role    = "roles/storage.admin"
  members = [
    "principal://iam.googleapis.com/projects/${data.google_project.main.number}/locations/global/workloadIdentityPools/${data.google_project.main.project_id}.svc.id.goog/subject/ns/default/sa/mediamtx",
    "principal://iam.googleapis.com/projects/${data.google_project.main.number}/locations/global/workloadIdentityPools/${data.google_project.main.project_id}.svc.id.goog/subject/ns/cooking/sa/mediamtx"
  ]
}


