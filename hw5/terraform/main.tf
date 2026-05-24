data "google_project" "project" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.project.number
  # GCS service agent that publishes Eventarc notifications to Pub/Sub
  gcs_sa = "service-${local.project_number}@gs-project-accounts.iam.gserviceaccount.com"
}

# ── APIs ──────────────────────────────────────────────────────────────────────

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "documentai" {
  service            = "documentai.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "aiplatform" {
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# ── Service account ───────────────────────────────────────────────────────────

resource "google_service_account" "pipeline" {
  account_id   = "hw5-pipeline-sa"
  display_name = "HW5 OCR Pipeline Service Account"

  depends_on = [google_project_service.iam]
}

# ── Project-level IAM for the SA ──────────────────────────────────────────────

resource "google_project_iam_member" "pipeline_documentai" {
  project = var.project_id
  role    = "roles/documentai.editor"
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_project_iam_member" "pipeline_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_project_iam_member" "pipeline_aiplatform_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.pipeline.email}"

  depends_on = [google_project_service.aiplatform]
}

# ── GCS Buckets ───────────────────────────────────────────────────────────────

resource "google_storage_bucket" "input" {
  name          = "${var.project_id}-${var.input_bucket_name}"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "ocr_output" {
  name          = "${var.project_id}-${var.ocr_output_bucket_name}"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "invoices" {
  name          = "${var.project_id}-${var.invoices_bucket_name}"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "company_data" {
  name          = "${var.project_id}-${var.company_data_bucket_name}"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket" "function_source" {
  name          = "${var.project_id}-hw5-function-source"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.storage]
}

# ── Bucket-level IAM (least-privilege) ───────────────────────────────────────

# OCR function: read PDFs from input bucket
resource "google_storage_bucket_iam_member" "pipeline_sa_input_viewer" {
  bucket = google_storage_bucket.input.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# OCR function: write JSON results to OCR output bucket
resource "google_storage_bucket_iam_member" "pipeline_sa_ocr_output_creator" {
  bucket = google_storage_bucket.ocr_output.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# Classify function: read OCR results from OCR output bucket
resource "google_storage_bucket_iam_member" "pipeline_sa_ocr_output_viewer" {
  bucket = google_storage_bucket.ocr_output.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# Classify function: write to invoices bucket
resource "google_storage_bucket_iam_member" "pipeline_sa_invoices_creator" {
  bucket = google_storage_bucket.invoices.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# Classify function: write to company-data bucket
resource "google_storage_bucket_iam_member" "pipeline_sa_company_data_creator" {
  bucket = google_storage_bucket.company_data.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

# ── Eventarc: allow GCS service agent to publish to Pub/Sub ──────────────────
# Without this, GCS cannot notify Eventarc and events are silently dropped.

resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${local.gcs_sa}"
}

# ── Eventarc service agent: needs storage.buckets.get to validate GCS triggers ─

resource "google_project_iam_member" "eventarc_service_agent" {
  project = var.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:service-${local.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"

  depends_on = [google_project_service.eventarc]
}

# ── Document AI OCR processor ─────────────────────────────────────────────────

resource "google_document_ai_processor" "ocr" {
  type         = "OCR_PROCESSOR"
  display_name = "hw5-ocr-processor"
  location     = var.docai_location

  depends_on = [google_project_service.documentai]
}

# ── Cloud Function source archives ────────────────────────────────────────────

data "archive_file" "ocr_source" {
  type        = "zip"
  output_path = "${path.module}/../function_source.zip"
  source_dir  = "${path.module}/../function"
}

resource "google_storage_bucket_object" "ocr_source" {
  name   = "ocr_function_${data.archive_file.ocr_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.ocr_source.output_path
}

data "archive_file" "classify_source" {
  type        = "zip"
  output_path = "${path.module}/../classify_source.zip"
  source_dir  = "${path.module}/../function_classify"
}

resource "google_storage_bucket_object" "classify_source" {
  name   = "classify_function_${data.archive_file.classify_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.classify_source.output_path
}

# ── OCR Cloud Function Gen 2 ──────────────────────────────────────────────────

resource "google_cloudfunctions2_function" "ocr" {
  name     = "hw5-ocr-function"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "process_document"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.ocr_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 300
    service_account_email = google_service_account.pipeline.email

    environment_variables = {
      PROJECT_ID     = var.project_id
      DOCAI_LOCATION = var.docai_location
      PROCESSOR_NAME = "projects/${var.project_id}/locations/${var.docai_location}/processors/${google_document_ai_processor.ocr.name}"
      OUTPUT_BUCKET  = google_storage_bucket.ocr_output.name
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.pipeline.email

    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.input.name
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_service.pubsub,
    google_project_service.artifactregistry,
    google_project_iam_member.gcs_pubsub_publisher,
    google_project_iam_member.eventarc_service_agent,
    google_project_iam_member.pipeline_eventarc_receiver,
    google_storage_bucket_object.ocr_source,
  ]
}

# ── Classification Cloud Function Gen 2 ───────────────────────────────────────

resource "google_cloudfunctions2_function" "classify" {
  name     = "hw5-classify-function"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "classify_document_event"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.classify_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 120
    service_account_email = google_service_account.pipeline.email

    environment_variables = {
      PROJECT_ID          = var.project_id
      VERTEX_REGION       = var.vertex_ai_region
      INVOICES_BUCKET     = google_storage_bucket.invoices.name
      COMPANY_DATA_BUCKET = google_storage_bucket.company_data.name
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.pipeline.email

    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.ocr_output.name
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_service.pubsub,
    google_project_service.artifactregistry,
    google_project_service.aiplatform,
    google_project_iam_member.gcs_pubsub_publisher,
    google_project_iam_member.eventarc_service_agent,
    google_project_iam_member.pipeline_eventarc_receiver,
    google_project_iam_member.pipeline_aiplatform_user,
    google_storage_bucket_object.classify_source,
  ]
}

# ── Cloud Run IAM: allow the trigger SA to invoke each function ───────────────

resource "google_cloud_run_v2_service_iam_member" "ocr_function_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloudfunctions2_function.ocr.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_cloud_run_v2_service_iam_member" "classify_function_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloudfunctions2_function.classify.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pipeline.email}"
}
