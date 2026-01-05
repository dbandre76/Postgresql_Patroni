##############################################
# Terraform configuration & Provider settings
##############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id       # GCP Project ID
  region  = var.region            # GCP Region
  zone    = var.zone              # GCP Zone
}

##############################################
# Networking resources (VPC, Subnet, etc)
##############################################

# VPC Network
resource "google_compute_network" "postgres_network" {
  name                    = "postgres-network"
  auto_create_subnetworks  = false   # We'll manually create subnets
}

# Subnet for PostgreSQL nodes
resource "google_compute_subnetwork" "postgres_subnet" {
  name          = "postgres-subnet"
  ip_cidr_range = var.subnet_cidr    # e.g. "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.postgres_network.id
}

# Firewall rules for PostgreSQL access
resource "google_compute_firewall" "allow_postgres" {
  name    = "allow-postgres"
  network = google_compute_network.postgres_network.name

  # Allow access to ports 22 (SSH) and 5432 (PostgreSQL)
  allow {
    protocol = "tcp"
    ports    = ["22", "5432"]
  }

  # CIDR block for source IP ranges (configurable)
  source_ranges = var.allowed_cidrs

  target_tags = ["postgres-nodes"]
}


# Firewall rules for etcd and patroni

resource "google_compute_firewall" "allow_patroni_etcd_external" {
  name    = "allow-patroni-etcd-external"
  network = google_compute_network.postgres_network.name

  allow {
    protocol = "tcp"
    ports = [
      "2379", # etcd client
      "2380", # etcd peer
      "8008"  # Patroni REST API
    ]
  }

  source_ranges = var.allowed_cidrs
  target_tags   = ["postgres-nodes"]
}


# grafana

resource "google_compute_firewall" "allow_monitoring_external" {
  name    = "allow-monitoring-external"
  network = google_compute_network.postgres_network.name

  allow {
    protocol = "tcp"
    ports = [
      "3000", # Grafana
      "9100"  # Node Exporter
    ]
  }

  source_ranges = var.allowed_cidrs
  target_tags   = ["postgres-nodes"]
}


##############################################
# Persistent Disks for PostgreSQL data
##############################################

# Persistent disk for /postgres (30 GB)
resource "google_compute_disk" "postgres_data" {
  count = var.node_count
  name  = "postgres-data-${count.index + 1}"
  type  = "pd-ssd"                       # SSD for better IOPS
  zone  = var.zone
  size  = var.postgres_disk_size  # Size in GB

}

# Persistent disk for /postgres_archive (10 GB)
resource "google_compute_disk" "postgres_archive" {
  count = var.node_count
  name  = "postgres-archive-${count.index + 1}"
  type  = "pd-ssd"         # SSD for better IOPS
  zone  = var.zone
  size  = var.archive_disk_size  # Size in GB

}

##############################################
# Compute Instances (PostgreSQL nodes)
##############################################

resource "google_compute_instance" "postgres_nodes" {
  count         = var.node_count
  name          = "postgres-node-${count.index + 1}"     # postgres-node-01, postgres-node-02
  machine_type  = var.instance_type                       # e.g. "e2-medium"
  zone          = var.zone


  # Boot disk configuration (Ubuntu)
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      type  = "pd-ssd"
      size  = var.root_disk_size  # Size in GB

    }
  }

  # Attach /postgres disk to each instance
  attached_disk {
    source      = google_compute_disk.postgres_data[count.index].id
    device_name = "postgres-data"
    mode        = "READ_WRITE"
  }

  # Attach /postgres_archive disk to each instance
  attached_disk {
    source      = google_compute_disk.postgres_archive[count.index].id
    device_name = "postgres-archive"
    mode        = "READ_WRITE"

  }

  # Networking (subnet, public IP)
  network_interface {
    network    = google_compute_network.postgres_network.id
    subnetwork = google_compute_subnetwork.postgres_subnet.id

    access_config {}  # Assign external IP
  }

  # Metadata (for SSH key injection)
  metadata = {
    ssh-keys = "dba:${file(var.ssh_public_key_content)}"
  }

  # Tags used for firewall rules
  tags = [
    "postgres-nodes"
  ]
}

##############################################
# End of main.tf
##############################################
