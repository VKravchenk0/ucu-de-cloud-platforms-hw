resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_sql_database_instance" "postgres" {
  name             = var.db_instance_name
  region           = var.region
  database_version = "POSTGRES_17"

  deletion_protection = false

  settings {
    tier    = var.db_tier
    edition = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled = true
    }

    backup_configuration {
      enabled = false
    }
  }

  depends_on = [
    google_project_service.sqladmin,
    google_project_service.compute,
  ]
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name

  depends_on = [google_sql_database_instance.postgres]
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password

  depends_on = [google_sql_database_instance.postgres]
}
