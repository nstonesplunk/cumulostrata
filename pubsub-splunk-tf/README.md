# Google Cloud Pub Sub to Splunk Terraform Automation
### Summary
TODO

### Prerequisites
* Install [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
* Create a GCP Service Account with `Owner`
	* Generate a JSON key for this Service Account and download to an accesible path
	* `export GOOGLE_CLOUD_KEYFILE_JSON={PATH TO SERVICE ACCOUNT JSON KEY FILE}`

### Deployment
* NOTE: There is currently a bug in the cloud function code when deployed using terraform.
	* Any occurence of `context.resource.get("name")` or `context.resource["name"]` should be replaced with `context.resource` for this deployment to work. (This can be done manually in the cloud function post terraform deployment)
* `cd pubsub-splunk-tf`
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