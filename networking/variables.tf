# this is networking/variables.tf in AWS2 project

# this is the vpc_cidr block in the root/main.tf
# this is now specified in the root/locals.tf file
variable "vpc_cidr" {
    type = string
}

# note that this is cidrs plural, as this is a list of subnets. See root/main.tf
variable "public_cidrs" {
    type = list
}

# this is for the private cidrs in root/main.tf
variable "private_cidrs" {
    type = list
}

# this is for the sunbet count variables in root/main.tf
variable "public_sn_count" { 
    type = number
}
variable "private_sn_count" {
    type = number
}

variable "max_subnets" {
    type = number
}

# this is the access ip list for the ingress security group in networking/main.tf
# We are using varible and then main/tfvars file so that the ip addesses are not going to
# be pushed to github as raw code in the terraform code files
variable "access_ip" {
    type = string
}

# add the root/locals.tf security_groups variable to the networking/variables.tf
# so that it can be used in networking/main.tf to create the security groups dynamically
variable "security_groups" {
    #let terraform deal with this type
}

# add the root/main.tf db_subnet_group so that it can be imported into this networking module
variable "db_subnet_group" {
    type = bool
    # this stands for boolean
}