output "input_bucket_name" {
  description = "Name of the input GCS bucket"
  value       = google_storage_bucket.input.name
}

output "output_bucket_name" {
  description = "Name of the output GCS bucket"
  value       = google_storage_bucket.output.name
}

output "function_name" {
  description = "Cloud Function Gen 2 name"
  value       = google_cloudfunctions2_function.ocr.name
}

output "function_uri" {
  description = "Cloud Function HTTP URI"
  value       = google_cloudfunctions2_function.ocr.service_config[0].uri
}

output "processor_name" {
  description = "Document AI processor full resource name"
  value       = google_document_ai_processor.ocr.name
}

output "service_account_email" {
  description = "Service account email used by the function"
  value       = google_service_account.ocr_function.email
}
