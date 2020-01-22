variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_project" "project" {}

resource "google_pubsub_topic" "gcs-splunk-topic" {
  name = "gcs-splunk"
}

resource "google_pubsub_topic" "retry-splunk-topic" {
  name = "retry-splunk"
}

resource "google_storage_bucket" "gcs-splunk-code-bucket" {
 	name = "gcs-splunk-code"
}

resource "google_storage_bucket_object" "gcs-splunk-code-object" {
  name = "gcs-splunk.zip"
  bucket = google_storage_bucket.gcs-splunk-code-bucket.name
  source = "./gcs-splunk-code/gcs-splunk.zip"
}

resource "google_cloudfunctions_function" "gcs-splunk-function" {
  name = "gcs-splunk"
  event_trigger {
    event_type = "providers/cloud.storage/eventTypes/object.change"
    resource = "splunkfunctiontest"
  }
  entry_point = "hello_gcs"
  runtime = "python37"
  service_account_email = google_service_account.gcs-splunk-sa.email
  source_archive_bucket = google_storage_bucket.gcs-splunk-code-bucket.name
  source_archive_object = google_storage_bucket_object.gcs-splunk-code-object.name
  environment_variables = {
    HEC_URL = "asdf"
    HEC_TOKEN = "asdf"
    PROJECTID = var.project_id
    RETRY_TOPIC = google_pubsub_topic.retry-splunk-topic.name
  }
}

resource "google_service_account" "gcs-splunk-sa" {
  account_id   = "gcs-splunk"
  display_name = "Service Account used by the gcs-snapshot Cloud Function"
}

resource "google_project_iam_binding" "gcs-splunk-sa-storage-admin-role" {
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.gcs-splunk-sa.email}"
  ]
}