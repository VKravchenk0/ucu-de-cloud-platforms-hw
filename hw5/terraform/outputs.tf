output "input_bucket_name" {
  description = "Name of the PDF input GCS bucket"
  value       = google_storage_bucket.input.name
}

output "ocr_output_bucket_name" {
  description = "Name of the intermediate OCR results GCS bucket"
  value       = google_storage_bucket.ocr_output.name
}

output "invoices_bucket_name" {
  description = "Name of the classified invoices GCS bucket"
  value       = google_storage_bucket.invoices.name
}

output "company_data_bucket_name" {
  description = "Name of the classified company data GCS bucket"
  value       = google_storage_bucket.company_data.name
}

output "ocr_function_name" {
  description = "OCR Cloud Function Gen 2 name"
  value       = google_cloudfunctions2_function.ocr.name
}

output "ocr_function_uri" {
  description = "OCR Cloud Function HTTP URI"
  value       = google_cloudfunctions2_function.ocr.service_config[0].uri
}

output "classify_function_name" {
  description = "Classification Cloud Function Gen 2 name"
  value       = google_cloudfunctions2_function.classify.name
}

output "processor_name" {
  description = "Document AI processor full resource name"
  value       = google_document_ai_processor.ocr.name
}

output "service_account_email" {
  description = "Service account email used by the pipeline functions"
  value       = google_service_account.pipeline.email
}
