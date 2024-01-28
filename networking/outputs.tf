# this is networking/outputs.tf in AWS2 project

# we need to create outputs in all of the modules in this project so that the root module 
# can consume them
output "vpc_id" {
    value = aws_vpc.aws2_vpc.id
    # id is one of the many attirubes of the aws vpc (see documentation)
}

# we need to create outputs for the subnet_group_name and the vpc_security_group_ids
# the next 2 outputs db_subnet_group_name and db_security_group are needed by the database module
# These will be outputted to the root/main.tf module "database" so that the database
# module can deploy the RDS servers
# These are passed as variables from root/main.tf into the database//main.tf
output "db_subnet_group_name" {
    value = aws_db_subnet_group.aws2_rds_subnetgroup.*.name
    # this attribute is in the networking/main.tf aws_db_subnet_group resource configuration
    #  The * gives us access to all of the subnet group names. THere is only one of them with it set to true in the conditional
}

output "db_security_group" {
    value = [aws_security_group.aws2_sg["private"].id]
    # id is one of the many attributes of the aws security group
    # this attribute is in the networking/main.tf aws_security_group resource configuration
    # but this uses the security_groups variable in root/locals.tf where it is defined with value = private for the rds network
    # This is a list? so enclosed in brackets
}


# the next 2 outputs pubic_sg and public_subnets are needed by the loadbalancing module
# These will be outputted to the root/main.tf module "loadbalancing" so that the loadbalancing
# module can deploy the application loadbalancer
# These are passed as varabiles from root/main.tf into the loadbalancing/main.tf

output "public_sg" {
    value = aws_security_group.aws2_sg["public"].id
    # this is very similar to the db_security_group output defined above
    # The only difference is that we are referencing the public rather than the private of the 
    # security group in the root/locals.tf file
}    
    
output "public_subnets" {
    value = aws_subnet.aws2_public_subnet.*.id
    # the asterik will pull all of the subnet ids
}


