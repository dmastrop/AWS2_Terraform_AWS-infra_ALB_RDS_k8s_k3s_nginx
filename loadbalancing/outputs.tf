# This is loadbalancing/outputs.tf in the AWS2 project

output "lb_target_group_arn" {
    value = aws_lb_target_group.aws2_tg.arn
    #resource is aws_lb_target_group and name aws2_tg and attribute is arn
    # arn is an attribute available for most resources.
    # This was used in the aws_lb_listener in loadbalancing/main.tf for the listener.
}

output "lb_endpoint" {
    value = aws_lb.aws2_lb.dns_name
    # we are using this to output the very important dns name of the ALB after terraform apply.
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
    # dns_name - The DNS name of the load balancer.
    # also we can see this in the terraform state in the terraform cloud since this is running state in the teraform cloud
    # current dns name of ALB for example is: http://aws2-loadbalancer-157741042.us-west-2.elb.amazonaws.com
    # A terraform state list and terrafomr state show module.loadbalancing.aws_lb.aws2_lb will also show the dns_name
}