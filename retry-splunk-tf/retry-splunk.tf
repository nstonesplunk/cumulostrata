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
  event_trigger = {
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