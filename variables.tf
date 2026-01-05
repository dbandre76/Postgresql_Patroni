variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the PostgreSQL subnet"
  type        = string
}

variable "instance_type" {
  description = "Type of machine for PostgreSQL nodes"
  type        = string
}

variable "node_count" {
  description = "Number of PostgreSQL nodes"
  type        = number
}

variable "allowed_cidrs" {
  description = "List of CIDR ranges allowed to connect to PostgreSQL"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "Public SSH key to access the PostgreSQL nodes"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key for remote connection"
  type        = string
}

variable "root_disk_size" {
  description = "Size of the root (/) disk in GB"
  type        = number
  default     = 25
}

variable "postgres_disk_size" {
  description = "Size of the /postgres disk in GB"
  type        = number
  default     = 35
}

variable "archive_disk_size" {
  description = "Size of the /postgres_archive disk in GB"
  type        = number
  default     = 10
}

