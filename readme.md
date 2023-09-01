1. Setting Up S3 Backend with Lock Table:


I decided to use the S3 backend with a lock table for storing and managing tfstate. So the first step is to create an S3 DynamoDB from the `initial-setup` folder:

Update the values of the variables in the `.env` file:
PROFILE=
REGION=
BACKEND_BUCKET_NAME=
BACKEND_LOCK_TABLE=

Initialize and start the creation of resources: 

source .env
terragrunt apply
Note down the values from the outputs for later use in the main code. 

2. Executing the main code:
Update the variables in the `test.env` or `prod.env` file (it can be used for any number of instances and types):
PROFILE=
REGION=
BACKEND_BUCKET_NAME="example-testate" # value from output from step 1
BACKEND_LOCK_TABLE="example-lock-table" # value from output from step 1
BACKEND_REGION="us-west-2" # value from output from step 1
AVAILABILITY_ZONES='["us-west-2a", "us-west-2b"]'
MODULE_VERSION=latest # name of the module folder
ENVIRONMENT=nonprod
NAME=test
Update the test.whitelist file to describe the rules for WAF:
{ host_regex = "^(foo|bar)\\.", path_regex = "\\/static\\/.*"},
{ host_regex = "^(foo|bar)\\.", path_regex = "\\/webhook$" },
{ host_regex = "^(foo)\\.", path_regex = "\\/webhooks\\/viber$" },
{ host_regex = "^(bar)\\.", path_regex = "\\/webhooks\\/facebook\\/webhook$"}

					
Initialize and start the creation of resources:
source test.env
terragrunt apply -var-file "test.whitelist"

3. httpie Test:			
Update the template with the list in urls.txt:
bar.{host}/webhooks/facebook/webhook
 
Execute the test:
./httpie_v2.sh urls.txt {host} # where {host} is the DNS name for ALB. For example, waf-acme-lb-2051087583.us-west-2.elb.amazonaws.com