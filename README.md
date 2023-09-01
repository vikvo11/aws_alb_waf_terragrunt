# aws_alb_waf_terragrunt

What is the goal?

  - create an AWS application load balancer (ALB) that is integrated
    with a web application firewall v2 (WAF).
  - the WAF should only allow certain hostname+location combinations to
    be explicitly whitelisted. all other combinations the WAF shall
    refuse with a suitable HTTP error code.
  - the infrastructure shall be deployed twice: once for stable use in a
    production environment "prod" and once in an environment that can be
    used to further develop the infrastructure and test it before
    applying changes to the production environment. That second
    environment "test" should mimic the "prod" environment as closely as
    necessary s.t. it is safe to assume if something works in "test" it
    will also work in "prod".
  - the infrastructure shall be described fully in code. organize your
    code in a way s.t.
     - it allows easy transitions of changes from "test" to "prod"
     - there is a manual approval step for changes applied to "prod"
     - it is possible to go back to a previously known state for "test"
       and for "prod"
     - it is possible to easily see the differences between "test" and
       "prod" (where "easily" means within under two minutes of human
       time but ideally with a single command that is only a few keystrokes
       away)

Tools

  - create a terragrunt/terraform module + instantiation that allows
    to whitelist certain hostname+location tuples provided as inputs
    to the module.
  - use of terragrunt is not necessary but definitely a plus.
  - fallback: if terraform modules are out of reach, create a
    monolithic terraform description of the setup and apply it.


Details for a single environment

  - create a new ALB called waf-acme-lb
  - put a t3.small ec2 behind the waf-acme-lb that runs a service on
    http:80 which echos back the hostname+location that was sent to
    it in the http request. we'll use that for debugging.
  - attach a regional WAFv2 to the ALB
  - create webacls on that WAF to allow the following combinations:

      (* is used in this example as any number of any characters)
      (A|B is used as alternatively A or B):

    - (foo|bar).waf-acme-lb.example.com/static/*
    - (foo|bar).waf-acme-lb.example.com/webhook
    - foo.waf-acme-lb.example.com/webhooks/viber
    - bar.waf-acme-lb.example.com/webhooks/facebook/webhook

  - you don't need to create the corresponding route53 entries.
  - you don't need to setup AWS ACM certificates, focus on http only


Acceptance Criteria

  - write a unix shell script using httpie or similar that shows:

    OK foo.waf-acme-lb.example.com/static/
    OK bar.waf-acme-lb.example.com/static/
    OK foo.waf-acme-lb.example.com/static/foo
    OK bar.waf-acme-lb.example.com/static/foo
    OK foo.waf-acme-lb.example.com/static/foo/bar
    OK bar.waf-acme-lb.example.com/static/foo/bar
    NA foo.waf-acme-lb.example.com/status
    NA bar.waf-acme-lb.example.com/status
    NA foo.waf-acme-lb.example.com
    NA bar.waf-acme-lb.example.com

    OK foo.waf-acme-lb.example.com/webhook
    OK bar.waf-acme-lb.example.com/webhook
    NA foo.waf-acme-lb.example.com/webhook/viber
    NA bar.waf-acme-lb.example.com/webhook/viber

    OK foo.waf-acme-lb.example.com/webhooks/viber
    NA bar.waf-acme-lb.example.com/webhooks/viber

    OK bar.waf-acme-lb.example.com/webhooks/facebook/webhook
    NA bar.waf-acme-lb.example.com/webhooks/facebook/webhook/foo
    NA foo.waf-acme-lb.example.com/webhooks/facebook/webhook

   where "OK" means that the page from the target group gets served with
   200 ok as status code and <hostname><location> as content.
   "NA" means that the WAF returns 403 forbidden.

  - organize your code and values in a way that is easy to explain
    and follow and can be extended to replacing the single "prod"
    environment to several production environments that need to be in
    different aws accounts with different approving parties (e.g.
    "prod-a", "prod-b", etc.)


Follow-up question for during the interview

  We would like to add support for API Key checking to your WAF module.
  For specific hostname+location combinations it should be possible to
  enforce usage of the correct API Key directly on the WAF. If for a
  specific location the use of an API Key 'foobarbaz' is required, it
  means that requests to that location will only be served if there is
  an additional HTTP header sent along:

    X-API-Key: foobarbaz

  If the header is missing or a wrong value is provided as key, the
  request should be rejected with a suitable HTTP error code. All
  locations for which the usage of an API Key is not mandatory should
  remain unchanged by that addition.

  - How would you extend your module?
  - What are advantages/disadvantages of checking API Keys on the WAF?


####

**Instruction for Installation and Usage:**

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



