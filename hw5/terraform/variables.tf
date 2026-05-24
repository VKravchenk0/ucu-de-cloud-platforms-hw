variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for all resources"
  type        = string
}

variable "docai_location" {
  description = "Document AI processor location (multi-region: 'eu' or 'us')"
  type        = string
  default     = "eu"
}

variable "input_bucket_name" {
  description = "Suffix for the PDF input GCS bucket"
  type        = string
  default     = "pdf-input"
}

variable "ocr_output_bucket_name" {
  description = "Suffix for the intermediate OCR results GCS bucket"
  type        = string
  default     = "ocr-results"
}

variable "invoices_bucket_name" {
  description = "Suffix for the classified invoices GCS bucket"
  type        = string
  default     = "invoices"
}

variable "company_data_bucket_name" {
  description = "Suffix for the classified company data GCS bucket"
  type        = string
  default     = "company-data"
}

variable "vertex_ai_region" {
  description = "Region for Vertex AI (Gemini) calls — must be a region that supports the chosen model"
  type        = string
  default     = "us-central1"
}
