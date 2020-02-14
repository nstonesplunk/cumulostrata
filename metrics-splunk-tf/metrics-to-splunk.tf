variable "project_id" {
  type = string
}

variable "hec_token" {
  type = string
}

variable "hec_url" {
  type = string
}

variable "metrics_list" {
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

resource "google_pubsub_topic" "metrics-splunk-topic" {
  name = "metrics-splunk"
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
    HEC_URL = var.hec_url
    HEC_TOKEN = var.hec_token
    PROJECTID = var.project_id
    METRICS_LIST	= var.metrics_list
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
resource "google_pubsub_topic" "retry-splunk-topic" {
  name = "retry-splunk"
}

resource "google_pubsub_subscription" "retry-splunk-subscription" {
  name  = "retry-splunk"
  topic = google_pubsub_topic.retry-splunk-topic.name
  ack_deadline_seconds = 60
}

resource "google_storage_bucket" "retry-splunk-code-bucket" {
 	name = "retry-splunk-code"
}

resource "google_storage_bucket_object" "retry-splunk-code-object" {
  name = "retry-splunk.zip"
  bucket = google_storage_bucket.retry-splunk-code-bucket.name
  source = "./retry-splunk-code/retry-splunk.zip"
}

resource "google_cloudfunctions_function" "retry-splunk-function" {
  name = "retry-splunk"
  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = google_pubsub_topic.retry-splunk-topic.name
  }
  entry_point = "hello_pubsub"
  runtime = "python37"
  service_account_email = google_service_account.retry-splunk-sa.email
  source_archive_bucket = google_storage_bucket.retry-splunk-code-bucket.name
  source_archive_object = google_storage_bucket_object.retry-splunk-code-object.name
  environment_variables = {
    PROJECTID = var.project_id
    SUBSCRIPTION = google_pubsub_subscription.retry-splunk-subscription.name
    RETRY_TRIGGER_TOPIC = google_pubsub_topic.retry-splunk-topic.name
  }
}

resource "google_service_account" "retry-splunk-sa" {
  account_id   = "retry-splunk"
  display_name = "Service Account used by the retry-snapshot Cloud Function"
}