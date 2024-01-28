# This is datastore/outputs.tf in the AWS2 project

# this output is required for the root/main.tf "compute" module, so that the userdata can be created on the EC2 node 
# and the userdata.tpl can be run on the EC2 (k3s node).  The userdata.tpl is what installs the k3s on the EC2 node so that it is
# a control node.  Note it is using the RDS database for the backend (database module).  RDS is up and running.
output "db_endpoint" {
    value = aws_db_instance.aws2_db.endpoint
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
    # endpoint attribute (this is in address:port format)
}