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

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_project" "project" {}

resource "google_pubsub_topic" "deadletter-splunk-topic" {
  name = "deadletter-splunk"
}

resource "google_pubsub_topic" "stackdriver-logs-topic" {
  name = "stackdriver-logs"
}

resource "google_pubsub_subscription" "stackdriver-logs-dataflow-subscription" {
  name  = "stackdriver-logs-dataflow-subscription"
  topic = google_pubsub_topic.stackdriver-logs-topic.name
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

resource "random_uuid" "bucket_guid" {}

resource "google_storage_bucket" "dataflow-splunk-job-temp-bucket" {
  name = "${random_uuid.bucket_guid.result}-splunk-dataflow"
}

resource "google_storage_bucket_object" "dataflow-splunk-job-temp-object" {
  name = "tmp/"
  content = "Placeholder to satisfy Dataflow requirements"
  bucket = "${google_storage_bucket.dataflow-splunk-job-temp-bucket.name}"
}

resource "google_dataflow_job" "splunk-dataflow-job" {
  name = "splunk-dataflow-streamin"
  template_gcs_path = "gs://dataflow-templates/latest/Cloud_PubSub_to_Splunk"
  temp_gcs_location = join("", ["gs://", "${google_storage_bucket.dataflow-splunk-job-temp-bucket.name}", "/tmp"])
  parameters = {
    inputSubscription	= "${google_pubsub_subscription.stackdriver-logs-dataflow-subscription.path}"
    token	= var.hec_token
    url	= var.hec_url
    outputDeadletterTopic = join("", ["projects/", "${var.project_id}", "/topics/", "${google_pubsub_topic.deadletter-splunk-topic.name}"])
  }
}

