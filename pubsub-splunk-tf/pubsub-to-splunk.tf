variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
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
  filter = "logName:\"/logs/cloudaudit.googleapis.com\" OR resource.type:gce OR resource.type=gcs_bucket OR resource.type=bigquery_resourc"
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

resource "google_storage_bucket" "pubsub-splunk-code-bucket" {
 	name = "pubsub-splunk-code"
}

resource "google_storage_bucket_object" "pubsub-splunk-code-object" {
  name = "pubsub-splunk.zip"
  bucket = google_storage_bucket.pubsub-splunk-code-bucket.name
  source = "./pubsub-splunk-code/pubsub-splunk.zip"
}

resource "google_cloudfunctions_function" "pubsub-splunk-function" {
  name = "pubsub-splunk"
  event_trigger = {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = google_pubsub_topic.stackdriver-logs-topic.name
  }
  entry_point = "hello_pubsub"
  runtime = "python37"
  service_account_email = google_service_account.pubsub-splunk-sa.email
  source_archive_bucket = google_storage_bucket.pubsub-splunk-code-bucket.name
  source_archive_object = google_storage_bucket_object.pubsub-splunk-code-object.name
  environment_variables = {
    HEC_URL = "asdf"
    HEC_TOKEN = "asdf"
    PROJECTID = var.project_id
    RETRY_TOPIC = google_pubsub_topic.retry-splunk-topic.name
  }
}

resource "google_service_account" "pubsub-splunk-sa" {
  account_id   = "pubsub-splunk"
  display_name = "Service Account used by the pubsub-snapshot Cloud Function"
}