output "instance_connection_name" {
  description = "Used with Cloud SQL Auth Proxy"
  value       = google_sql_database_instance.postgres.connection_name
}

output "public_ip" {
  description = "Cloud SQL public IP address"
  value       = google_sql_database_instance.postgres.public_ip_address
}

output "db_name" {
  value = google_sql_database.db.name
}

output "db_user" {
  value = google_sql_user.user.name
}
