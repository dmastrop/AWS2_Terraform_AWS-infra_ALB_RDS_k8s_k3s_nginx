# This is compute/outputs.tf in AWS2 project

# LATEST TERRAFORM VERSION: For a first round of this just  output everthing from the compute module
#COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
output "instance" {
    value = aws_instance.aws2_node[*]
    # this will interate through all instances and output everything so that we can display it to terminal using the root/outputs.tf file
    # This is called "instance" because the output will be done per instance via [*]
}    




# # OLDER TERRAFORM VERSIONS: For a first round of this just  output everthing from the compute module
# # COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
# output "instance" {
#     value = aws_instance.aws2_node[*]
#     # this will interate through all instances and output everything so that we can display it to terminal using the root/outputs.tf file
#     # This is called "instance" because the output will be done per instance via [*]
    
#     # NOTE in older terraform versions, since we are outputting everything from the compute aws_instance and using in root/outputs.tf
#     # to display in terminal, this throws and erro and requires the following line here (and in root/outputs.tf) to avoid the error:
    
#     sensitive = true
    
#     # in later and current terraform version these sensitive output values are automatically tagged and this line is not required!!!
# }




# this next block is for appending the instance port (in this case tg_port which is 8000) to the output in root/outputs.tf for the 
# instance ip: port. The format should be like   "aws2_node-14503" = "44.234.252.19:8000”
output "instance_port" {
    value = aws_lb_target_group_attachment.aws2_tg_attach[0].port
    # this will export the port used for the target group attachment. Note that we use [0] which is the port assigned to the first EC node instance
    # this is because [1] node will have the same port anyways. So we can us [0].port for both "instance_port" on both nodes!!!
}