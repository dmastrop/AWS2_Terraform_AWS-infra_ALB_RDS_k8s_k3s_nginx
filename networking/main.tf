# This is networking/main.tf in AWS2 project

# add availability_zones datsource here or can create datasources.tf file
data "aws_availability_zones" "available" {}

# to address the issue of aws_availability zone exhausion at 4 subnets
# we need to use the random_shuffle resource
resource "random_shuffle" "az_list" {
    input = data.aws_availability_zones.available.names
    result_count = var.max_subnets
}
    
    
# create a random integer for new number for each new vpc instance
resource "random_integer" "random" {
    min = 1
    max =100
}

# create the vpc 
resource "aws_vpc" "aws2_vpc" {
# don't hardcode the cidr block since this is a terraform module
    cidr_block = var.vpc_cidr
    # Note there is no quotes around "var.vpc_cidr"
    # this will provide a dns hostname for any resource deployed in public environment
    # for example we will be able to access loadblancer with this fqdn
    enable_dns_hostnames = true
    enable_dns_support = true
    
    # this tag will create a unique vpc name for each instance
    tags = {
        Name = "aws2_vpc-${random_integer.random.id}"
    }
    
    lifecycle {
    create_before_destroy = true
    # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle
    # this will create a new vpc before destroying the current vpc so that the
    # internet gw can be updated when the cidr_block network is changed
    # Changing the cidr_block requires all subnets and the current vpc to be destroyed and
    # the current internet gw to be rebound to the new vpc that is created
    # If the new vpc is created before the old one is destroyed, the internet gw will
    # be able to be rebound to the new vpc and the new subnets created in the new cidr_block!!
    }
    
}

# here we will create the 2 public aws subnets in the vpc. We will use the imported networking/variables.tf file to 
# import the variables from the root/main.tf, for example var.vpc_cidr and var.public_cidrs
# aws_subnet. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "aws2_public_subnet" {
   
    # use the length of the var.public_cidrs that is specified as a list in root/main.tf
    ##count = length(var.public_cidrs)
    
    # for the non-hardcoded version use the following:
    count = var.public_sn_count
    
    #create the subnets in the vpc resource above
    vpc_id = aws_vpc.aws2_vpc.id
    cidr_block = var.public_cidrs[count.index]
    # on first iteration with count.index=0 it will pull the first public subnet from root/main.tf and on the
    # second iteration with count.index=1 it will pull the second public subnet from root/main.tf.  Each is a single block pulled from the
    # list of public_cidrs in root/main.tf
    map_public_ip_on_launch = true
    # this will ensure that addressses launched in this subnet will be public ip addresses. Default is false
    ##availability_zone = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"][count.index]
    # these availabiily zones can be found by creating a dummy subnet in this vpc in AWS2. For now we will hardcode it, but later will remove hardcoding.
    # use the [count.index] to pull only a single availability_zone per iteration. 
    
    #Use the datasource availability_zones defined above and get rid of the hardcoded availablility zone list above
    # this is the non-hardcoded version
    ##availability_zone = data.aws_availability_zones.available.names[count.index]
    
    # Next iteration for the availability_zone issue that limits to 4 subnets, incrporate the random_suffle above
    # this is only limited by the max_subnets as defined in root/main.tf.  For now set at 20
    # this will alow up to 20 subnets each for public and private subnets
    # Note that data.aws_availability_zones.available.names is incorporated into the random_suffle now
    availability_zone = random_shuffle.az_list.result[count.index]
    
    tags = {
        Name = "aws2_public_${count.index + 1}"
    }
    
}

# With the routing at bottom
# This is for public subnet to get linked up to the internet gw specified below in routing section
resource "aws_route_table_association" "aws2_public_assoc" {
    #note that each public subnet has to be directly linked up to the internet gw so we need to use the count
    # and interate through all public_sn_count public subnets. (public_sn_count is defined in root/main.tf)
    count = var.public_sn_count
    subnet_id = aws_subnet.aws2_public_subnet.*.id[count.index]
    route_table_id = aws_route_table.aws2_public_rt.id
    # this is the public route table defined in routing section below
    # basically all public subnets will be hooked to the internet gw for default routing so that
    # traffic can be routed out to the outside world
}


# Next create the 3 private subnets in this same vpc
resource "aws_subnet" "aws2_private_subnet" {
    
    # use the length of the var.private_cidrs that is specified as a list in root/main.tf
    ##count = length(var.private_cidrs)
    
    # for the non-hardcoded version use the following:
    count = var.private_sn_count
   
    #create the subnets in the vpc resource above
    vpc_id = aws_vpc.aws2_vpc.id
    cidr_block = var.private_cidrs[count.index]
    # on first iteration with count.index=0 it will pull the first private subnet from root/main.tf and on the
    # second iteration with count.index=1 it will pull the second private subnet from root/main.tf, and on third iteration it will 
    # pull the third private subnet with count.index=2.  Each is a single block pulled from the
    # list of private_cidrs in root/main.tf
    map_public_ip_on_launch = false
    # this will ensure that addressses launched in this subnet will be public ip addresses. Default is false so we can remove this or set to false
    ##availability_zone = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"][count.index]
    # these availabiily zones can be found by creating a dummy subnet in this vpc in AWS2. For now we will hardcode it, but later will remove hardcoding.
    # use the [count.index] to pull only a single availability_zone per iteration. 
    
    #Use the datasource availability_zones defined above and get rid of the hardcoded availablility zone list above
    # this is the non-hardcoded version
    ##availability_zone = data.aws_availability_zones.available.names[count.index]
    
    # Next iteration for the availability_zone issue that limits to 4 subnets, incrporate the random_suffle above
    # this is only limited by the max_subnets as defined in root/main.tf.  For now set at 20
    # this will alow up to 20 subnets each for public and private subnets
    # Note that data.aws_availability_zones.available.names is incorporated into the random_suffle now
    availability_zone = random_shuffle.az_list.result[count.index]
    
    tags = {
        Name = "aws2_private_${count.index + 1}"
    }
    
}






# Routing
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table


## PUBLIC ROUTING
# Only 1 internet gw per VPC
resource "aws_internet_gateway" "aws2_internet_gateway" {
    vpc_id = aws_vpc.aws2_vpc.id
    
    tags = {
        Name = "aws2_igw"
    }
    
}

resource "aws_route_table" "aws2_public_rt" {
    vpc_id = aws_vpc.aws2_vpc.id
    
    tags = {
        Name = "aws2_public"
    }
}

# default route is where all traffic goes without specific route. We want this to be the internet gw above
# this will be used for all the public ip addressed subnets. They will go out to the internet by default
resource "aws_route" "default_route" {
    route_table_id = aws_route_table.aws2_public_rt.id
    # default traffic will be sent out to the public route table
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws2_internet_gateway.id
}

# connect the public subnets to the public route table so that they can use the internet gw to route traffic
# to the outside world (internet gw) see ABOVE aws2_public_subnet and right below it is the route table association





## PRIVATE ROUTING
# default route table is the route table our subnets will use if they have not been associated with one
# this is all our private subnets in the aws2_vpc
# all private subnets are not assocationed with a route table so they will sue this default vpc route table
resource "aws_default_route_table" "aws2_private_rt" {
    default_route_table_id = aws_vpc.aws2_vpc.default_route_table_id
    # every vpc gets a default route table.  This was created by the vpc.
    
    tags = {
        Name = "aws2_private"
    }
}


# SECURITY GROUPS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
##resource "aws_security_group" "aws2_sg" {
##    name = "public_sg"
##    description = "Security Group for Public Access"
##    vpc_id = aws_vpc.aws2_vpc.id
##    ingress {
##        from_port = 22
##        to_port = 22
##        protocol = "tcp"
##        cidr_blocks = [var.access_ip]
        # this needs to be in brackets because this will be a list of cidr blocks
        # this variable will be a list of allowable cidr blocks for the SSH traffic
        # Rather than publishing the list to the repository as code in github it is best
        # to use a root/tfvars file and then pass the ip addesses from the root tfvars file and into 
        # this networking/main.tf module/file
##    }

##    egress {
##        from_port = 0
##        to_port = 0
##        protocol = "-1"
##        cidr_blocks = ["0.0.0.0/0"]
        # outbound traffic will have access to all networks that are required
##    }
##}

# overhaul the original security group definition using a for_each loop and the 
# locals.security_groups variable configured in root/locals.tf
# This will permit a more dynamic creation of security groups so that the rules can be scaled 
# up accordingly
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks

resource "aws_security_group" "aws2_sg" {
    for_each = var.security_groups
    
    name = each.value.name
    # value is for example = public or private.  name for example = "public_sg"
    # added a second security group with name = "rds_sg". (value = private)
    # "public_sg" will be applied to public subnets and "rds_sg" will be applied to private subnets
    # see the root/locals.tf file where these are defined
    # This will enable us to create multiple security groups in public and/or private subnets
    
    description = each.value.description
   
    # vpc_id is static and the same across all security groups
    vpc_id = aws_vpc.aws2_vpc.id
    
    # for ingress block will use a dynamic block
    dynamic "ingress" {
        for_each = each.value.ingress
        # value for example is public
        # there can be multiple ingress rules per security group, so we need to nest this
        # for_each loop in the main for_each loop above
        # for example, for the ingress rules for the security group "public_sg" there is an ssh
        # rule and a newly added http rule
        
        content {
            from_port = ingress.value.from
            # value here is ssh for example, etc....
            to_port =ingress.value.to
            protocol = ingress.value.protocol
            cidr_blocks = ingress.value.cidr_blocks
            # this needs to be in brackets because this will be a list of cidr blocks
            # this variable will be a list of allowable cidr blocks for the SSH traffic
            # Rather than publishing the list to the repository as code in github it is best
            # to use a root/tfvars file and then pass the ip addesses from the root tfvars file and into 
            # this networking/main.tf module/file
        }
        
    }
    
    # We do not need a dynamic block for egress since this will be the same across all security groups
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        # outbound traffic will have access to all networks that are required
    }
}

# Create the VPC RDS subnet group and the conditionals
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "aws2_rds_subnetgroup" {
    count = var.db_subnet_group == true ? 1 : 0
    # ALTERNATE SYNTAX: count = var.db_subnet_group == ? 1 : 0
    # for the count use the db_subnet_group variable defined in root/main.tf under module networking
    # this is imported via the networking/variables.tf file
    # if db_subnet_group is set to true in root/main.tf then set count = 1
    # if db_subnet_group is set to false in root/main.tf then set count = 0 and do not create this
    # aws_db_subnet_group resource
    name = "aws2_rds_subnetgroup"
    subnet_ids = aws_subnet.aws2_private_subnet.*.id
    # any of our private subnets (3 of them in base case) can be used in this rds subnet group
    tags = {
        Name = "aws2_rds_sng"
    }
}





