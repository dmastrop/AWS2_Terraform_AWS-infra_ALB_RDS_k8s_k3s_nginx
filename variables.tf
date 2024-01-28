# this is root/variables.tf in root of AWS2 project

variable "aws_region" {
    default = "us-west-2"
    # this is a good region because it has 4 availability zones.
    # other reason is Cloud9 IDE is in us-west-1 so this prevent confusion about what is going on
}

# this is the access ip list for the ingress security group in networking/main.tf
# We are using varible and then main/tfvars file so that the ip addesses are not going to
# be pushed to github as raw code in the terraform code files
# note that this variable is used in root/main.tf and passed to networking/main.tf where it is used as part 
# of the construct of the ingress security group (public)
variable "access_ip" {
    type = string
}

# add this variable for my pc ip address
variable "access_ip_pc" {
    type = string
}


# These are the database variables that we moved from root/main.tf  database module to terraform.tfvars

variable "dbname" {
   #type = "string"
   type = string
}

variable "dbuser" {
    #type = "string"
    type = string
    sensitive = true
    # this will prevent it from being outputted on terraform display
}

variable "dbpassword" {
    #type = "string"
    type = string
    sensitive = true
    # this will prevent it from being outputted on terraform display
}

# NOTE: quoted "true" should also be cleaned up and quotes removed even though it validates still.




