# Stackdriver Metrics to Splunk Terraform Automation
### Summary
This template will send Stackdriver Metrics to Splunk using the HTTP Event Collector (HEC) method. Which metrics are sent are determined by a provided list of Stackdriver metrics on template deployment. This template has a configurable trigger time and the default sending interval is every 5 minutes.

### Prerequisites
* Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
* Create a GCP Service Account with `Owner`
	* Generate a JSON key for this Service Account and download to an accesible path
	* `export GOOGLE_CLOUD_KEYFILE_JSON={PATH TO SERVICE ACCOUNT JSON KEY FILE}`

### Deployment
* `cd metrics-splunk-tf`
* `terraform init`
* `terraform apply`
	* Provide requested variables when prompted
		* Note: hec_url format is http(s)://{HOSTNAME}:{PORT} (Ex. https://127.0.0.1:8088)
	* Type `yes` to confirm creation of resources

### Cleanup
* `terraform destroy`
	* Provide requested variables when prompted
	* Type `yes` to confirm deletion of resources
	* See Troubleshooting section below

### Troubleshooting
* In Progress