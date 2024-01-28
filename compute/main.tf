# This is compute/main.tf for AMI and EC2 compute instances in AWS2 project


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "server_ami" {
    most_recent = true
    # we will pull the most recent version if avaiable
    owners = ["099720109477"]
    # owners are the same for all x86 ubuntu image versions
    
    # for the filter
    # the * will ensure that we always get the latest version
    # use the AMI name and subsitute the date at the end with an asterik
    # AMI name 22.04 ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207
    # AMI name 20.04 ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20231025
    filter {
        name = "name"
        
        # removed asterik due to some sort of bug with the ami-id getting set invoalid with terraform plan
        # Unfortunately very bad timing.  The terraform proposed ami-id was built at the same time I was coding this
        # The ....dac ami-008fe2fc65df48dac is current ami-id, the ....22e9 ami-0ce2cb35386fc22e9 is a mystery ami-id in the image buider on AWS, and the terraform
        # proposed ami-id ...ami-07f28b7760ac74a33 is the just published 1/18/24 image.
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
        #values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}




# create a random id to diffrentiate the various EC2 instances
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "random_id" "aws2_node_id" {
    byte_length = 2
    count = var.instance_count
    
    # add keepers. This is so that if something is changed that requires the current EC2 instance to be terminated and recreated....
    # that we always get a new name (new random_id which is used to create the EC2 name). Currently, without keeepers, 
    # if we, for example, add a pubic key to the EC2 instance and the instance is re-created, the name will stay the same.
    # Best way to do this is use the AMI-id (instance id).  If that changes we can create a new random id and thus name for the EC2
    # instance.... Another more direct approach is to watch for the key_name
    # https://registry.terraform.io/providers/hashicorp/random/latest/docs#resource-keepers
    keepers = {
        # Generate a new id each time we switch to a new AMI id
        # ami_id = var.ami_id
        
        # more direct apparoch with the key_name....
        key_name = var.key_name
    }
}
    
    
    
    
    
# create the aws_key_pair
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "aws2_auth" {
    key_name = var.key_name
    
    # use the file function
    # https://developer.hashicorp.com/terraform/language/functions/file
    public_key = file(var.public_key_path)
}
    
    
    
    
    
    
# create the EC2 instance resource
resource "aws_instance" "aws2_node" {
    count = var.instance_count # 1
    
    instance_type = var.instance_type # t3.micro. this is required for k3 resources to launch containers. This is not in the free
    # tier.  It is free in Stockholm eu-north-1 region. You can use same region as it is not very expensive (full time is 5-10/month)
    
    ami = data.aws_ami.server_ami.id # see above data resource
    
    tags = {
        Name = "aws2_node-${random_id.aws2_node_id[count.index].dec}" #dec is the decimal of the random_id that is used
    }


   key_name = aws_key_pair.aws2_auth.id
   # see the aws_key_pair resource above
   
   vpc_security_group_ids = [var.public_sg]
   subnet_id = var.public_subnets[count.index]
   
   # This next block is for the user_data which will use the userdata.tpl file to install the k3s onto our EC2 nodes (in public subnet)subnet_id
   # reference urls are below
   
   # NOTE this will use the backend database (see below: db_endpoint)
   # the userdata.tpl essentially downloads the k3s software to the database so that it can be installed on each of the EC2 control nodes
   
   # https://docs.k3s.io/installation
   # https://docs.k3s.io/datastore/ha
   # https://developer.hashicorp.com/terraform/language/functions/templatefile
   # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
   
   # templatefile(path,vars)
   # path is where we have put the userdata.tpl script. This is in the root of the Cloud9 IDE AWS2 project in my workspace
   # Better to user var.user_data_path as the path so it can be easily modified in the future.
   # This varaible will be specified in root/main.tf under module "compute" as a varaible value for user_data_path = "$(path.root}/userdata.tpl"
   # Contents of the userdata.tpl file are below::
   
    #   curl -sfL https://get.k3s.io | sh -s - server \
    # --datastore-endpoint="mysql://${dbuser}:${dbpass}@tcp(${db_endpoint})/${dbname}" \
    # --write-kubeconfig-mode 644 \
    # --tls-san=$(curl http://169.254.169.254/latest/meta-data/public-ipv4) \
    # --token="th1s1sat0k3n!"   <<< this part is new requirement
    
   # the template file vars need to be passed next
   # nodename,  dbuser, dbpass, dbname, and  db_endpoint which are used in the userdata.tpl file to execute the intallation of k3s onto the 
   # EC2 nodes

   user_data = templatefile(var.user_data_path, 
    {
        #nodename = "aws2_node-${random_id.aws2_node_id[count.index].dec}"
        
        # the nodename is going to be used as hostname of the installed EC2 node instance
        # This hostname shouuld show up if we ssh into the instance (terminal prompt)
        # Recall this is set in tags above in this resource: aws2_node-${random_id.aws2_node_id[count.index].dec}
        
        ## NOTE: loadbalancers do not like underscores (recall this in ALB loadbalancers)
        ## kubernetes also does not like underscores so we need to remove the underscore in the above nodename
        ## and use the following nodename. This is because this will be used as dns hostname.  Can't use underscores
        ## NOTE that count.index is used becasue we have more than one EC2 node.
        ## The nodename is the hostname (when do SSH to the EC2 node, this will be the hostname, for example aws2-31387)
        nodename = "aws2-${random_id.aws2_node_id[count.index].dec}"
        
        
        dbuser = var.dbuser
        dbpass = var.dbpassword
        # note there is no requirement that the variable name dbpassword be the same name as the prameter
        # name that we are passing into the userdata.tpl file.  It is called dbpass in the userdata.tpl file and
        # we simply decided to user dbpassword as the name of the variable in compute/main.tf and compute/varaibles.tf
        db_endpoint = var.db_endpoint
        dbname = var.dbname
    }
    
   # terminate the () for the templatefile function below
   )    
   
   
   root_block_device  {
       volume_size = var.vol_size # 10 Gigibytes within fee tier
    }
    
    
    
    # Insert the remote provisioner "remote-exec" to access whether or not the k3s is bootstrapped. Using this we can 
    # remove the sleep 60 in the scp_script.tpl file that is used to pull over the kubeconfig to our Cloud9 IDE.
    # Note that the remote provisioner has be be done prior to the local provisioner.
    # The remote provioner will use SSH to do this.  It will SSH into the instance and then run the delay.sh script on the instance
    # As long as the kubeconfig file k3s.yaml is NOT present, it will be waiting.
    # Once the file does exist, then the local-exec below this is executed to pull the k3s.yaml to our local Cloud9 IDE instance so that
    # we can configure the nodes from the Cloud9 IDE instance (kubectl...)
    provisioner "remote-exec" {
        # first do the connection block
        connection {
            type = "ssh"
            user = "ubuntu"
            # this is the default user of the ubuntu Cloud9 instance (we also use this to SSH into EC2 instances from Cloud9 IDE, etc.)
            host = self.public_ip
            # this is running within the compute aws_instance block so we can use the self referral
            
            #private_key = file("/home/ubuntu/.ssh/keyaws2")
            # this is the full path to the local private ssh key that we have been using
            # Replace this private_key value with the variable var.private_key_path as described below
            private_key = file(var.private_key_path)
        }
        
        # next pass the script. This script will be executed as a shell script on the EC2 ssh session terminal.
        script = "${path.cwd}/delay.sh"
        # note that path.cwd refers to the root and not the path within this compute module (/root and not /root/compute)
        # So this file needs to be with the others (scp_script.tpl and userdata.tpl) in root
    }
    
    
    # add the local provisioner to the aws_instance compute so that we can administer kubectl from Cloud9 IDE rather than
    # having to SSH in locally to EC2 instance to run it
    # We can also consolidate the .yaml files into the Cloud9 IDE project as well.
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
    
    # This is what the scp_script.tpl file does:
        # first wait 60 seconds to make sure k3s has time to bootstrap
        # we will use remote provisioner to get around this in the future
        # scp in using ssh key that we have created. For me this is aws2key instead of mtckey
        # turn off host key checking which will interrupt the script from running
        # login in using the node_ip and pull the k3s.yaml file which is the kubeconfig file and pull it into one up from root Cloud9 instance and replace the localhost ip (127.0.0.1) in the file with the node_ip address (public) of the EC2 instrance. 
        # This will allow us to remotely access the k3s cluster and administrate remotely from the Cloud9 IDE
        # This final file with the node_ip will be renamed k3s-<nodename>.yaml one up from the local Cloud9 project. This will allow remote provisioning of the k3s cluster from the Cloud9 instance.

    provisioner "local-exec" {
        command = templatefile("${path.cwd}/scp_script.tpl",
        # note path.cwd or path.root. Current working directory is root.
        {
        # this is the templatefile function variables list:
            nodeip = self.public_ip
            k3s_path = "${path.cwd}/../"
            # we want to go up one level so that the k3s_path is outside of root of this project so that we do not commit this kubeconfig .yaml file to github
            nodename = self.tags.Name
            # this is the name of the node. See above tags and Name definition
            
            # add this private_key_path so that the scp_script.tpl private key path that is used can be easily changed if required.
            private_key_path = var.private_key_path
            
        }
        )
    }
    
    
    # add another local provisioner to delete the .yaml kubeconfig files from the Cloud9 IDE directory (one above root for the project)
    # This should only be done on destroy and needs to iterate through all of the currently running instance names via self.tags.Name
    provisioner "local-exec" {
        when = destroy
        command = "rm -f ${path.cwd}/../k3s-${self.tags.Name}.yaml"
    }
    
    
#end resource aws_instance 
}


# Add nodes to target group and allow loadbalancer to send traffic to the EC2 node nginx targets
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
resource "aws_lb_target_group_attachment" "aws2_tg_attach" {
    count = var.instance_count
    target_group_arn = var.lb_target_group_arn
    # this value will be supplied from root/main.tf which will do a module call to the loadbalancing mudule to get the tg arn
    target_id = aws_instance.aws2_node[count.index].id
    # we are getting the instance id from each of the EC2 nodes and we are attaching to the target group for the loadbalancer to use
    # note that these are EC2 instance ids and we are just calling them target_ids in the context of this target group attachment
    
    #port = 8000
    # reason not using port 80 is because port 80 is being used by kubernetes resources within the node
    # See extensive NOTE in root/main.tf on how this overrides the tg_port specified in root/main.tf and the loadbalancing/main.tf configurations
    # Currently tg_port is set to 8000 but changing it to 80 makes no difference in the traffic setup and flow.  However, terraform apply
    # causes new target group attachemnt arns and a new target group to be created (the ALB listener is updated in place)
    
    # For consistency, let's set this target group attachment port (above hadcoded to 8000) to the same as the var.tg_port used in root/main.tf and loadbalancing/main.tf
    # This will make things less confusing.
    port = var.tg_port
    
}    
