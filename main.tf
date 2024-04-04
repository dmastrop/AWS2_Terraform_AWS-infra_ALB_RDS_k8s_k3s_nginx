# this is root/main.tf in AWS2 project

#Move this to newly created root/locals.tf
# create a locals block to simpify the specificatoin of cidr block below
##locals {
##    vpc_cidr = "10.123.0.0/16"
    #vpc_cidr = "10.124.0.0/16"
##}

# create the vpc and reference the networking module
module "networking" {
    source = "./networking"
    # the variables below need to be passed to the terraform networking module through networking/variables.tf file
    # next set the vpc_cidr variable value that is used by the netorking module to create the vpc
   ## vpc_cidr = "10.123.0.0/16"
   
   # use the locals above to simplify the value setting of the vpc_cidr block above. Also use this in the cidrsubnet function below as well.
   vpc_cidr = local.vpc_cidr
   
   
   access_ip = var.access_ip
   # this access ip will be passed to the networking module as a variable var.access_ip and used in the ingress security group in networking/main.tf
   
   #like the vpc_cidr above, use the locals.tf file to specify the security_groups to be passed to the networking/main.tf so that the security groups can be created more dynamically
   security_groups = local.security_groups
   
   # SUBNETTING: 
    # use even numbers for public subnets in the vpc, and odd numbers for the private subnets in the vpc
    # aws_subnet. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet is defined in networking/main.tf
    ##public_cidrs = ["10.123.2.0/24", "10.123.4.0/24"]
    ##private_cidrs = ["10.123.1.0/24", "10.123.3.0/24", "10.123.5.0/24"]
    
    # Revise the hardcoding above and use the range() function and the cidrsubnet() function
    # use public_sn_count and private_sn_count for the actual deployed subnet count as we don't want to create 100s of subnets
    # these variables will be used as the count in networking/main.tf
    ##public_sn_count = 2
    ##private_sn_count = 3
    ######### set these for number of subnets #########
    
    public_sn_count = 2
    private_sn_count = 3
    
    # max_subnets is for the aws_availability_zones exhaustion issue at count of 4
    # using resource random_shuffle in networking/main.tf will resolve this issue
    # But the result_count must be set for the random az_list that is returned
    # we can set this to 20 for now.  In general since the random_suffle az_list is kept in state 200 is not a good idea (200 is AWS soft limit for subnets).  With a 20 max we can go up to 20 subnets for each private and public subnets.
    max_subnets = 20
    
    ##public_cidrs = [for i in range(2, 255, 2) : cidrsubnet("10.123.0.0/16", 8, i)]
    # this will create 255 subnets, even though AWS has softlimit of 200. This will ensure we always have enough subnets on hand
    ##private_cidrs = [for i in range(1, 255, 2) : cidrsubnet("10.123.0.0/16", 8, i)]
    
    # use the locals above for the cidr block values in the cidrsubnet functions above to simplify things
    public_cidrs = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
    # this will create 255 subnets, even though AWS has softlimit of 200. This will ensure we always have enough subnets on hand
    private_cidrs = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
    
    # this is the conditional for the RDS subnet group
    # This variable is imported into the networking module via the networking/variables.tf file
    #  Set this to true if the setup has RDS and to false if it does not have RDS
    db_subnet_group = true

}



# create the database module for the RDS setup
# set the value for all of the imported variables that go into the database module
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance

## BEGIN MULTILINE COMMENT OUT (temporary for ALB rollout). In Cloud9 use Edit Comment Coment Toggle from menu
## Remove comment out for the userdata rollout on the EC2 instances so that we can deploy the k3s application on the EC2 nodes
module "database" {
    source = "./database"
    # next define all the variables. Later migrate to terraform.tfvars
    db_storage = 10 # in Gibibytes
    #db_engine_version = "5.7.22"
    db_engine_version = "8.0.32"
    # this is minimum 5.7.37 now. See this link
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Concepts.VersionMgmt.html
    # 4/2024 end of standard support for 5.7 was on 2/2024
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/extended-support.html
    # use extended support version.   5.7.37 is no longer avaiable.
    # try 5.7.44 This did not work: 
    # RDS does not support creating a DB instance with the following combination: DBInstanceClass=db.t2.micro, Engine=mysql, EngineVersion=
    # 5.7.44, LicenseModel=general-public-license.
    # try 8.0.32.  Instance class db.t2.micro is not supported. Try changing that 
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Db2.Concepts.General.InstanceClasses.html
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
    # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html#SQLServer.Concepts.General.InstanceClasses
    
    #db_instance_class = "db.t2.micro"
    db_instance_class = "db.t3.small"
    
    # MOVE dbname dbuser and dbpassword to terraform.tfvars
    # for security so that these do not get pushed to github.
    ##dbname = "rancher" # rancher k3s
    ##dbuser = "bobby"
    ##dbpassword = "password123"
    dbname = var.dbname
    dbuser = var.dbuser
    dbpassword = var.dbpassword
    
    db_identifier = "aws2-db"
    skip_db_snapshot = true 
    # in prod this is set to false; in dev set to true
    db_subnet_group_name= module.networking.db_subnet_group_name[0]
    # empty "" for now.  These will be populated with outputs
    # the output is from the networking/outputs.tf module so module.networking is used here
    # see networking/outputs.tf file
    # the [0] will reference the first of the subnet group names. There is currently only one of them. (count =1 in networking/main.tf aws_db_subnet_group count = true which is 1)
    vpc_security_group_ids = module.networking.db_security_group 
    # empty list [ ]for now. These will be populated with outputs. These are the private security group ids.
    # the output is from the networking/outputs.tf module so module.networking is used here
    # see networking/outputs.tf file
    # security groups uses the root/locals.tf file and networking/outputs.tf has to reference the value = private 
}



# create the loadbalancing module
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
module "loadbalancing" {
    source = "./loadbalancing"
    # these next 2 variables need to be built from outupts from the networking module
    # networking/outputs.tf is where the outputs will be defined from the networking module. This is very similar to what was done for the database module above
    # NO quotes around these values below!!!!!
    public_sg = module.networking.public_sg
    public_subnets = module.networking.public_subnets
    
    # these below are for the target group of the ALB
    # we can move the following variables below to tarraform.tfvars later if required for security
    # NOTE that these are variables and not resource parameters. For example use tg_port and not port
    # port is used in the resource itself which is defined in loadblancing/main.tf and not here
    # this is simply a module call to the loadbalancing/main.tf so that resources can be created.
    
    # changing the tg_port causes issues with the loadbalancer because the target group must be destroyed
    # and created again but during the period where there is no target group, the listener will have no place to go
    # use the lifecycle in the loadbalancing/main.tf and create_before_destroy = true. The target group will not be destroyed until the new tg is configured.  
    #In this way the listener wil be able to be destroyed
    
    #tg_port = 80
    tg_port= 8000
    # NOTES on this:
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#port
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
    # target group port var.tg_port vs. the target group attachment port(s).  The tg_port is a loadbalncing and root configuration
    # The ports in the target group attachment are a compute/main.tf configuration.
    # The tg_port in root/main.tf loadbalancing module (ths configuration) and used in loadbalancing/main.tf is overriden with the 
    # ports specified in the target group attachment in compute/main.tf
    # Per documentation on the target group port (tg_port): "Port on which targets receive traffic, unless overridden when
    # registeringspecific target. " 
    # (i.e., unless overriden with the port specified in the target group attachment on the nodes in compute/main.tf)
    # The current configuration has tg_port set to 8000 and the target group attachment port in compute/main.tf set to 8000
    # If the target group attachment port is removed (it is optional), whatever the tg_port is configured at will be the ports that
    # will be used when sending traffic to the EC2 nodes in the target group!!!!!
    
    tg_protocol = "HTTP"
    vpc_id = module.networking.vpc_id
    # note that this is already defined as an output in networking/outputs.tf due to earlier usage
    lb_healthy_threshold = 2
    lb_unhealthy_threshold = 2
    lb_timeout = 3
    lb_interval = 30
    
    # these are the variables for the ALB listener
    # issue with target groups and changing the listener port
    # https://stackoverflow.com/questions/57183814/error-deleting-target-group-resourceinuse-when-changing-target-ports-in-aws-thr
    # use the lifecycle in the loadbalancing/main.tf for this (ignore_changes = [name])
    #listener_port = 8000
    listener_port = 80
    # use port 8000 as a test. The nginx instances will receive traffic on 8000 and we will be sending trafifc to the 
    # ALB listener on port 8000 as well. The nginx can be reached directly on each EC2 node via 8000 and the loadbalancer will be able to 
    # send traffic to the nodes on 8000 as well.  In browser hit the DNS name :8000
    # Next test out listener port on ALB on 80. Note that the target ports are still 8000 on backend.  This is just for the ALB
    # In browser hit the DNS name on port 80
    listener_protocol = "HTTP"
}


# create the compute module
module "compute" {
    source = "./compute"
    # these next 2 variables need to be built from outupts from the networking module
    # networking/outputs.tf is where the outputs will be defined from the networking module. This is very similar to what was done for the database module above
    # NO quotes around these values below!!!!!
    public_sg = module.networking.public_sg
    public_subnets = module.networking.public_subnets
    
    instance_count = 2  # change this to 2 for kubernetes so that we can deploy 2 nginix containers.  Since we are using hostPort 
    # and not nodePort in the deployment.yaml on the EC2 instance we can only run 1 container instance of the same type per kubernetes
    # node.
    
    # note that this instance_count is the terraform AWS2 infra node deployment (EC2 instances) and is not related to the 
    # replicas count in the k8s yaml files. The two are completely independent.
    
    #instance_type = "t3.micro" 
    # note this is not in free tier in us-west. We need this for the k3s control plane node to deploy docker containers to it. We cannot use t2.micro
    
    # For running the full k3s with the nginx pods, etc... we need to upgrade the instance_type to t2.small or t3.small so that the nodes
    # remain stable as the CI/CD infra is brought up.  I have already upgraded the Cloud9 IDE instances to t2.small so I will use
    # t2.small for this deployment.
    #instance_type = "t2.small"
    
    # t2.small is not supported in us-west2d!!! try out t3.small.  According to AWS EC2 t3.small is supported in all 4 avaiability zones.
    # Lots of issues with this.
    instance_type = "t3.small"
    
    vol_size = 10
    
    # these variables are for the aws_key_pair SSH
    key_name = "aws2key"
    
    # test for the keepers in the random_id resource in compute/main.tf
    # with the keepers this will cause the EC2 instance to get a new name because the random_id resource will be regenerated!!
    #key_name = "aws2keynew"
    

    # keyaws2.pub is the public key we generated with the ssh-keygen -t rsa. The private key is named keyaws2
    public_key_path = "/home/ubuntu/.ssh/keyaws2.pub"
    
    
    
    
    
    ## USERDATA values for variables required by userdata in the compute/main.tf user_data to load
    ## k3s onto the EC2 aws_instances
    ## https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
    
    # the next line is for the userdata.tpl file that is used to load k3s code onto the EC2 nodes in the compute/main.tf AWS EC2 instance resource
    # See the compute/main.tf file. It is used in the termplatefile() function to load the userdata.tpl
    # file into the instance so that it can be executed and install the k3s code.
    # Note that userdata.tpl is in the root directory of my AWS2 project in the Cloud9 IDE instance workspace.
    # Note use curly brackets and not () for ${path.root}
    user_data_path = "${path.root}/userdata.tpl"
    
    # the next lines are the other variables that are requjird by the userdata.tpl file used in compute/main.tf to deploy k3s
    # See compute/main.tf.  These are all used in teh templatefile function 
    # note that as indicated above the values for these are moved to terraform.tfvars for security
    # These varaibles are already declared in the root/varaibles.tf file
    dbname = var.dbname
    dbuser = var.dbuser
    dbpassword = var.dbpassword
    
    # finally the last variable required by the userdata.tpl file used in compute/main.tf to deploy k3s in templatefile function
    # is the db_endpoint.  The actual value from this will be from datastore/outputs.tf file (need to do)
    # This will be a module call to database similar to those done earlier for public_sg and public_subnets, etc in networking
    db_endpoint = module.database.db_endpoint
    
    
    # this next section is for the target group attachment.  The code has been added to compute/main.tf and variables.tf
    # the target group arn requires a module call to the loadbalancing module
    lb_target_group_arn = module.loadbalancing.lb_target_group_arn
    
    # This is for changing the target group attachment port in compute/main.tf from hardcoding 8000 to using the var.tg_port that we
    # used in the loadbalancing module above.
    tg_port = 8000
    
    # Define the value of the private_key_path that is used in the local and remote provisioners in the compute/main.tf module and 
    # passed to the scp_script.tpl file
    # Note public_key_path already defined earlier above for this module.
    private_key_path = "/home/ubuntu/.ssh/keyaws2"
}

