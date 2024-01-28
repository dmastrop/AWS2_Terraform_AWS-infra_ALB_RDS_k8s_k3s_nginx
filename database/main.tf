# This is database/main.tf in AWS2 project

# there is a lot of cut and paste here for the large database configuration in terraform
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# these variables are set in root/main.tf where the database module is configured
# and are passed to this module through database/variables.tf.
resource "aws_db_instance" "aws2_db" {
    allocated_storage = var.db_storage # in gibibytes
    engine = "mysql" # hardcoded
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class 
    # size of the instance that we will use
    
    #name = var.dbname 
    # name has been deprecated and is now db_name
    db_name = var.dbname
    
    username = var.dbuser
    password = var.dbpassword
    db_subnet_group_name = var.db_subnet_group_name 
    # subnet group name is from the networking module 
    # and is set in the root/main.tf through networking/outputs.tf
    vpc_security_group_ids = var.vpc_security_group_ids 
    # referenced from the networking module
    # and is set in the root/main.tf through networking/outputs.tf 
    
    identifier = var.db_identifier # identifier of the db instance
    skip_final_snapshot = var.skip_db_snapshot # this is true or false
    tags = {
        Name = "aws2-db"
    }
}