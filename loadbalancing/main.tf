# This is loadbalancing/main.tf in AWS2 project

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "aws2_lb" {
    # note that name cannot use an underscore. This shows up as an error in 
    # terraform validate
    #name = "aws2_loadbalancer"
    name = "aws2-loadbalancer"
    
    # use an imported variable for the subnets
    # root/main.tf will get this from the newtorking module as an outputted varaible
    # and pass it to this module loadbalancing/main.tf
    # brackets around var.public_subnets is not required.  THe initial requirement was due to a syntax error
    # in root/main.tf with the module calls to the networking module to pull the values as outputs from networking module accidentally
    # put in quotes
    subnets = var.public_subnets
    
    # security groups is a list. Use an imported variable for this
    # root/main.tf will get this from the networking module as an outputted variable
    # and pass it to this moudule loadbalancing/main.tf
    security_groups = [var.public_sg]
    
    # once can use variable for idle timeout, but hardcoding is ok in most cases
    idle_timeout = 400
}

# create the target group resource for the ALB defined above
# Use the uuid and substr to create a unique target group name
# Note with names cannot use underscore, must use hyphen instead
#https://developer.hashicorp.com/terraform/language/functions/substr
#https://developer.hashicorp.com/terraform/language/functions/uuid
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
resource "aws_lb_target_group" "aws2_tg" {
    name = "aws2-lb-tg-${substr(uuid(), 0, 3)}"
    
    port = var.tg_port # 80
    # See extensive NOTE in root/main.tf on how this tg_port is overriden by the port specified in the target group attachment in compute/main.tf
    # Currently tg_port is set to 8000 but changing it to 80 makes no difference in the traffic setup and flow.  However, terraform apply
    # causes new target group attachemnt arns and a new target group to be created (the ALB listener is updated in place)
    
    protocol = var.tg_protocol # "HTTP"
    vpc_id = var.vpc_id # this needs to be pulled from networking module (note that it has already been added to 
    # networking/outputs.tf due to earlier requirement)
    
    # everytime we make any change or even a terraform plan,  the target group name changes and the target group is redeployed
    # This is too disruptive (traffic goes down, etc), and if just the name is changed, we should ignore the name change
    # This will make it so that we can change the listener port in root/main.tf, and then apply it to take effect without the target group
    # being destoryed and recreated
    # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
    # https://stackoverflow.com/questions/57183814/error-deleting-target-group-resourceinuse-when-changing-target-ports-in-aws-thr
    # The next issue is that if the tg port is changed in root/main.tf, the target group will be replaced but there is a problem because
    # the old tg is destroyed BEFORE the new one is created and the listener has no place to bind during this period where there is no target group
    # This creates a problem during apply and destroy,  With create_before_destroy on the tg, the tg will be able to be destroyed.  With create_before_destroy the
    # listener will have a place to go after the current tg is destroyed.  Without create_before_destory the tg won't be able to be destroyed.
    # For this we need to set the create_before_destroy = true.
    lifecycle {
        ignore_changes = [name]
        create_before_destroy = true
    }
    
    health_check {
        # can use dynamic blocks but for now use static
        healthy_threshold = var.lb_healthy_threshold # set to 2
        unhealthy_threshold = var.lb_unhealthy_threshold # set to 2
        timeout = var.lb_timeout # 3
        interval = var.lb_interval # 30
    }
}


# create the ALB listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "aws2_lb_listener" {
    # note that the actual arns can be seen in terraform cloud under the latest runs
    load_balancer_arn = aws_lb.aws2_lb.arn
    port = var.listener_port # port 80
    protocol = var.listener_protocol # "HTTP"
    default_action {
    # this is how any traffic sent to port 80 is treated by default
    type = "forward"
    target_group_arn = aws_lb_target_group.aws2_tg.arn
    }
   
}