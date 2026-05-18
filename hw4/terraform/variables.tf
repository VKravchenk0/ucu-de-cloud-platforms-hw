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
  description = "Suffix for the input GCS bucket name"
  type        = string
  default     = "documents-input"
}

variable "output_bucket_name" {
  description = "Suffix for the output GCS bucket name"
  type        = string
  default     = "documents-output"
}
