# Retry to Splunk Terraform Automation
### Summary
TODO

### Prerequisites
* Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
* Create a GCP Service Account with `Owner`
	* Generate a JSON key for this Service Account and download to an accesible path
	* `export GOOGLE_CLOUD_KEYFILE_JSON={PATH TO SERVICE ACCOUNT JSON KEY FILE}`

### Deployment
* `cd retry-splunk-tf`
* `terraform init`
* `terraform apply`
	* Provide your GCP Project ID when prompted
	* Type `yes` when prompted

### Cleanup
* `terraform destroy`
	* Provide your GCP Project ID when prompted
	* Type `yes` when prompted
	* See Troubleshooting section below