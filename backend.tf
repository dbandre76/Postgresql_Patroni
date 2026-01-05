terraform {
  backend "gcs" {
    bucket  = "snowflake-01"
    prefix  = "terraform/postgres-patroni"
  }
}
