output "service_url" {
  value = google_cloud_run_v2_service.app.uri
}

output "trigger_id" {
  value = google_cloudbuild_trigger.trigger.id
}