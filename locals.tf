# This is root/locals.tf

#Move this to newly created root/locals.tf
# create a locals block to simpify the specificatoin of cidr block below
locals {
    vpc_cidr = "10.123.0.0/16"
    #vpc_cidr = "10.124.0.0/16"
}

locals {
# note security_groups plural. This is going to be a list of all the security groups
# this is not security_group (That is the resource as specified in the networking/main.tf file)
    security_groups = {
        public = {
            name = "public_sg"
            # this is the name of the public sg in netorking/main.tf
            description = "Security Group for Public Access"
            ingress = {
                
                # create an open access ingress rule for now for the SCP and kubectl access to the nodes for the access_ip
                # Note for now I have the terraform.tfvars var.access_ip wide open. In reality this should be locked down to
                # the ip address of my Cloud9 IDE instance and my PC ip address.  See below. This is done
                # Note opening all ports because the k8s control from the Cloud9 IDE will require port 6443 access.
                open = {
                    from = 0
                    to = 0
                    protocol = -1
                    
                    #cidr_blocks = var.access_ip
                    # if have more than one address in var.access_ip in terraform.tfvars then remove the brackets here and use
                    # brackets in the terraform.tfvars file access_ip = ["dddress_1", "address_2"]
                    # This is not working for me
                    # https://www.udemy.com/course/terraform-certified/learn/lecture/24924036#questions/14996332
                    
                    cidr_blocks = [var.access_ip]
                    # if havejust one address in the terraform.tfvars like access_ip = "0.0.0.0/0" then use the brackets here for
                    # the cidr_blocks. I will use this for now and lock it down to the Cloud9 IDE ip address instance.
                }    
                
                # Given the open access rule above we can comment out the ssh rule below as everything is open for now for var.access_ip
                # first ingress rule in this security group
                # ssh = {
                #     from = 22
                #     to = 22
                #     protocol = "tcp"
                #     cidr_blocks = [var.access_ip]
                # }  
                
                
                # add another rule for open all for my pc.  I can have SSH terminal access from PC and VSCode with this.
                 openpc = {
                    from = 0
                    to = 0
                    protocol = -1
                    
                    cidr_blocks = [var.access_ip_pc]

                }    
                
                    
                # second ingress rule in this security group    
                http = {
                    from = 80
                    to = 80
                    protocol = "tcp"
                    cidr_blocks = ["0.0.0.0/0"]
                }
                
                # nginix containers on the kubernetes 2 public nodes
                # these are listening on container port 80 but hostPort exposed is 8000. See the deployment.yaml file on first node that
                # we used to kubectl apply -f  the configuration
                nginx = {
                    from = 8000
                    to = 8000
                    protocol = "tcp"
                    cidr_blocks = ["0.0.0.0/0"]
                }
            }
            
        }
        
        private = {
            name = "rds_sg"
            description = "Security Group for RDS Access with the vpc_cidr block"
            # RDS is on private subnet so this needs to be applied to private subnet so that other 
            # subnets in the vpc_cidr block can access the RDS private subnet
            ingress = {
                mysql = {
                    from = 3306
                    to = 3306
                    protocol = "tcp"
                    cidr_blocks = [local.vpc_cidr]
                    # this block is specified at the top of this locals.tf file
                    # all subnets on this entire block will have access into the RDS private subnet with this security groups
                    # applied to the private subnet (RDS servers)
                }
            }
        }
    }
}