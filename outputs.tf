##############################################
# Outputs for PostgreSQL Nodes (GCP)
##############################################

output "postgres_public_ips" {
  description = "Public IPs of the PostgreSQL nodes"
  value = google_compute_instance.postgres_nodes[*].network_interface[0].access_config[0].nat_ip
}

output "postgres_private_ips" {
  description = "Private IPs of the PostgreSQL nodes"
  value = google_compute_instance.postgres_nodes[*].network_interface[0].network_ip
}

output "vpc_id" {
  description = "VPC ID where PostgreSQL nodes are deployed"
  value = google_compute_network.postgres_network.id
}

output "subnet_id" {
  description = "Subnet ID used by PostgreSQL nodes"
  value = google_compute_subnetwork.postgres_subnet.id
}

output "firewall_rule" {
  description = "Firewall rule allowing PostgreSQL access"
  value = google_compute_firewall.allow_postgres.id
}
