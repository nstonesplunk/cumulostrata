# Google Cloud Stackdriver to Splunk (through Dataflow) Terraform Automation
### Summary
This template will create a logging export to Cloud PubSub based on a user provided Stackdriver Logging filter. The template also deploys a streaming Dataflow template that sends events from the Cloud PubSub sink topic to Splunk using the HTTP Event Collector method.

### Prerequisites
* Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
* Create a GCP Service Account with `Owner`
	* Generate a JSON key for this Service Account and download to an accesible path
	* `export GOOGLE_CLOUD_KEYFILE_JSON={PATH TO SERVICE ACCOUNT JSON KEY FILE}`

### Deployment
* `cd stackdriver-dataflow-splunk-tf`
* `terraform init`
* `terraform apply`
	* Provide requested variables when prompted
		* Note: hec_url format is {HOSTNAME}:{PORT} (Ex. 127.0.0.1:8088)
	* Type `yes` to confirm creation of resources

### Cleanup
* `terraform destroy`
	* Provide requested variables when prompted
	* Type `yes` to confirm deletion of resources
	* See Troubleshooting section below

### Troubleshooting
* In Progress