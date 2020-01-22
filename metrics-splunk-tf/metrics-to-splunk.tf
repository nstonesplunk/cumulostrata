variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_project" "project" {}

resource "google_pubsub_topic" "metrics-splunk-topic" {
  name = "metrics-splunk"
}

resource "google_pubsub_topic" "retry-splunk-topic" {
  name = "retry-splunk"
}

resource "google_storage_bucket" "metrics-splunk-code-bucket" {
 	name = "metrics-splunk-code"
}

resource "google_storage_bucket_object" "metrics-splunk-code-object" {
  name = "metrics-splunk.zip"
  bucket = google_storage_bucket.metrics-splunk-code-bucket.name
  source = "./metrics-splunk-code/metrics-splunk.zip"
}

resource "google_cloud_scheduler_job" "metrics-splunk-scheduler-job" {
  name = "metrics-splunk-scheduler"
  schedule = "*/5 * * * *"
  time_zone = "America/Los_Angeles"

  pubsub_target {
    topic_name = google_pubsub_topic.metrics-splunk-topic.id
    data = base64encode("trigger")
  }
}

resource "google_cloudfunctions_function" "metrics-splunk-function" {
  name = "metrics-splunk"
  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = google_pubsub_topic.metrics-splunk-topic.name
  }
  entry_point = "hello_pubsub"
  runtime = "python37"
  service_account_email = google_service_account.metrics-splunk-sa.email
  source_archive_bucket = google_storage_bucket.metrics-splunk-code-bucket.name
  source_archive_object = google_storage_bucket_object.metrics-splunk-code-object.name
  environment_variables = {
    HEC_URL = "asdf"
    HEC_TOKEN = "asdf"
    PROJECTID = var.project_id
    METRICS_LIST	= "[\"compute.googleapis.com/instance/cpu/utilization\",\"compute.googleapis.com/instance/disk/read_ops_count\",\"compute.googleapis.com/instance/disk/read_bytes_count\",\"compute.googleapis.com/instance/disk/write_bytes_count\",\"compute.googleapis.com/instance/disk/write_ops_count\",\"compute.googleapis.com/instance/network/received_bytes_count\",\"compute.googleapis.com/instance/network/received_packets_count\",\"compute.googleapis.com/instance/network/sent_bytes_count\",\"compute.googleapis.com/instance/network/sent_packets_count\",\"compute.googleapis.com/instance/uptime\",\"compute.googleapis.com/firewall/dropped_bytes_count\",\"compute.googleapis.com/firewall/dropped_packets_count\"]"
    TIME_INTERVAL	= "5"
    RETRY_TOPIC = google_pubsub_topic.retry-splunk-topic.name
  }
}

resource "google_service_account" "metrics-splunk-sa" {
  account_id   = "metrics-splunk"
  display_name = "Service Account used by the metrics-splunk Cloud Function"
}

resource "google_project_iam_binding" "metrics-splunk-sa-monitoring-viewer-role" {
  role    = "roles/monitoring.viewer"
  members = [
    "serviceAccount:${google_service_account.metrics-splunk-sa.email}"
  ]
}