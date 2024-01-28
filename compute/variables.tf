# This is compute/variables.tf in AWS2 project

variable "instance_count" {}

variable "instance_type" {}

variable "public_sg" {}

variable "public_subnets" {}

variable "vol_size" {}

# these are for the aws_key_pair SSH
variable "key_name" {}

variable "public_key_path" {}

# this next variables are used in the user_data definition in the compute/main.tf aws_instance resource for the
# userdata loading onto the EC2 instance_count
# 5 total varaibles required for this.  db_endpoint will require a module call to database by root/main.tf
# the other 4 are direcctly or indirectly set in the root/main.tf (indirectly is via terraform.tfvars)
variable "user_data_path" {}

variable "dbuser" {}

variable "dbpassword" {}

variable "db_endpoint" {}

variable "dbname" {}

# the next variable is for the target group attachment
# the value for this will be passed from the root/main.tf via a module call to the loadbalancing module
variable "lb_target_group_arn" {}

# we are going to use the var.tg_port in the aws loadbalancing target group attachment port to simplify things
# In theory they do not need to be the same. See extensive NOTE on this in root/main.tf
variable "tg_port" {}

# this next variable is the variable for the private key path and private key
# this is used in the scp_script.tpl and also in the local provisioner in compute/main.tf as a variable that is passed into 
# scp_script.tpl via the templatefile command.
variable "private_key_path" {}