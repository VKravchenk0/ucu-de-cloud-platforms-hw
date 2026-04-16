variable "github_app_installation_id" {
  type = number
}

locals {
  project_number = data.google_project.project.number

  image_base_url = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repository_id}/${var.service_name}"

  cloudbuild_sa = "${local.project_number}@cloudbuild.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_iam_member" "cloudbuild_artifact" {
  project = var.project_id
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_secret" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${local.cloudbuild_sa}"
}

resource "google_artifact_registry_repository" "repo" {
  repository_id = var.repository_id
  location      = var.region
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifact
  ]
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_connection_secret" {
  project   = var.project_id
  secret_id = "github-pat"
  role      = "roles/secretmanager.secretAccessor"

  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"

  depends_on = [
    google_project_service.secretmanager
  ]
}

resource "google_cloudbuildv2_repository" "repo" {
  project           = var.project_id
  location          = var.region
  name              = var.github_repo

  # created manually via UI
  parent_connection = "github-connection"

  depends_on = [
    google_project_service.cloudbuild
  ]

  remote_uri = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}

resource "google_cloudbuild_trigger" "trigger" {
  project  = var.project_id
  location = var.region
  name     = "${var.service_name}-deploy"

  repository_event_config {
    repository = google_cloudbuildv2_repository.repo.id

    push {
      branch = "^${var.github_branch}$"
    }
  }

  service_account = google_service_account.cloudbuild.id

  build {
    images = [
      "${local.image_base_url}:$COMMIT_SHA"
    ]

    options {
      logging = "CLOUD_LOGGING_ONLY"
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t", "${local.image_base_url}:$COMMIT_SHA",
        "."
      ]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "${local.image_base_url}:$COMMIT_SHA"]
    }

    step {
      name       = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run",
        "deploy",
        var.service_name,
        "--image=${local.image_base_url}:$COMMIT_SHA",
        "--region=${var.region}",
        "--platform=managed",
        "--allow-unauthenticated"
      ]
    }
  }

  depends_on = [
    google_project_service.cloudbuild,
    google_project_service.artifact
  ]
}

resource "google_cloud_run_v2_service" "app" {
  name     = var.service_name
  location = var.region
  deletion_protection = false

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }

  lifecycle {
    ignore_changes = [template[0].containers[0].image]
  }

  depends_on = [ google_project_service.run ]
}

# Public access to the app
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = google_cloud_run_v2_service.app.project
  location = google_cloud_run_v2_service.app.location
  name     = google_cloud_run_v2_service.app.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

resource "google_service_account" "cloudbuild" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
}

resource "google_project_iam_member" "cloudbuild_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

resource "google_project_iam_member" "cloudbuild_sa" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}