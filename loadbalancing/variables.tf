# This is loadbalancing/variables.tf in AWS2 project


# the first set of variables are for the loadbalancer itself
variable "public_sg" {}

variable "public_subnets" {}

# the next set of variables are for the target group
variable "tg_port" {}

variable "tg_protocol" {}

variable "vpc_id" {}

variable "lb_healthy_threshold" {}

variable "lb_unhealthy_threshold" {}

variable "lb_timeout" {}

variable "lb_interval" {}

# the next set of variables are for the listener resource 
variable "listener_port" {}

variable "listener_protocol" {}


