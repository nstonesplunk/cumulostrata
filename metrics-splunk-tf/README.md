# Stackdriver Metrics to Splunk Terraform Automation
### Summary
TODO

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
	* Type `yes` to confirm creation of resources

### Cleanup
* `terraform destroy`
	* Provide requested variables when prompted
	* Type `yes` to confirm deletion of resources
	* See Troubleshooting section below

### Troubleshooting
* TODO