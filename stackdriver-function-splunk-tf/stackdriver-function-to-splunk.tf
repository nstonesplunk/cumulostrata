variable "project_id" {
  type = string
}

variable "hec_token" {
  type = string
}

variable "hec_url" {
  type = string
}

variable "logging_filter" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_project" "project" {}

resource "google_pubsub_topic" "retry-splunk-topic" {
  name = "retry-splunk"
}

resource "google_pubsub_topic" "stackdriver-logs-topic" {
  name = "stackdriver-logs"
}

resource "google_logging_project_sink" "audited-resource-logs-pubsub-sink" {
  name = "audited-resource-logs-pubsub"
  destination = "pubsub.googleapis.com/projects/${data.google_project.project.project_id}/topics/${google_pubsub_topic.stackdriver-logs-topic.name}"
  filter = var.logging_filter
  unique_writer_identity = true
}

resource "google_project_iam_binding" "pubsub-log-writer" {
  role = "roles/pubsub.publisher"

  members = [
    google_logging_project_sink.audited-resource-logs-pubsub-sink.writer_identity,
  ]
}

resource "google_project_iam_binding" "pubsub-log-viewer" {
  role = "roles/pubsub.viewer"

  members = [
    google_logging_project_sink.audited-resource-logs-pubsub-sink.writer_identity,
  ]
}

resource "google_storage_bucket" "stackdriver-function-splunk-code-bucket" {
 	name = "stackdriver-function-splunk-code"
}

resource "google_storage_bucket_object" "stackdriver-function-splunk-code-object" {
  name = "stackdriver-function-splunk.zip"
  bucket = google_storage_bucket.stackdriver-function-splunk-code-bucket.name
  source = "./stackdriver-function-splunk-code/stackdriver-function-splunk.zip"
}

resource "google_cloudfunctions_function" "stackdriver-function-splunk-function" {
  name = "stackdriver-function-splunk"
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.stackdriver-logs-topic.name
  }
  entry_point = "hello_pubsub"
  runtime = "python37"
  service_account_email = google_service_account.stackdriver-function-splunk-sa.email
  source_archive_bucket = google_storage_bucket.stackdriver-function-splunk-code-bucket.name
  source_archive_object = google_storage_bucket_object.stackdriver-function-splunk-code-object.name
  environment_variables = {
    SPLUNK_SOURCE = google_pubsub_topic.stackdriver-logs-topic.name
    HEC_URL = var.hec_url
    HEC_TOKEN = var.hec_token
    PROJECTID = var.project_id
    RETRY_TOPIC = google_pubsub_topic.retry-splunk-topic.name
  }
}

resource "google_service_account" "stackdriver-function-splunk-sa" {
  account_id   = "stackdriver-function-splunk"
  display_name = "Service Account used by the stackdriver-function-snapshot Cloud Function"
}