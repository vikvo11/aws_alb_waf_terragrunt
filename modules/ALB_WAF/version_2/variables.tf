variable "profile" {

}
variable "aws_region" {

}
########
variable "env" {
}
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "module_version" {
}

#########

variable "whitelist" {
  description = "A list of hostname regex and location tuples to whitelist"
  type        = list(object({ host_regex = string, path_regex = string }))
  #type        = list(object({ host_regex = string, path_regex = string, api_key = string }))
  default = [

    # { host_regex = "^(foo|bar)\\.", path_regex = "\\/static\\/.*", api_key = "foobarbaz"},
    # { host_regex = "^(foo|bar)\\.", path_regex = "\\/webhook$", api_key = "foobarbaz" },
    # { host_regex = "^(foo)\\.", path_regex = "\\/webhooks\\/viber$", api_key = "foobarbaz" },
    # { host_regex = "^(bar)\\.", path_regex = "\\/webhooks\\/facebook\\/webhook$", api_key = "foobarbaz"}


  ]
}