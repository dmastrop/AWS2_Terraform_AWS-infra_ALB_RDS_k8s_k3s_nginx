# This is root/outputs.tf in the AWS2 project

output "load_balancer_endpoint" {
    value = module.loadbalancing.lb_endpoint
    # see the loadbalancing/outputs.tf file
}


# # LATEST TERRAFORM VERSION: this next block is for outputting EC2 compute instance information from the compute/outputs.tf file
# COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
# output "instances" {
#     value = {for i in module.compute.instance : i.tags.Name => i.public_ip}
#     # this will access the Name tag from compute/main.tf in the resource aws_instance.aws2_node and map it to its respective public_ip address
# }





# # OLDER TERRAFORM VERSIONS: this next block is for outputting EC2 compute instance information from the compute/outputs.tf file
# # COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
# output "instances" {
#     value = {for i in module.compute.instance : i.tags.Name => i.public_ip}
#     # this will access the Name tag from compute/main.tf in the resource aws_instance.aws2_node and map it to its respective public_ip address

#     # NOTE in older terraform versions, since we are outputting everything from the compute aws_instance and using in root/outputs.tf
#     # to display in terminal, this throws and error and requires the following line here (and in compute/outputs.tf) to avoid the error:
    
#     sensitive = true
    
#     # in later and current terraform version these sensitive output values are automatically tagged and this line is not required!!!
    
    
# }




# # OLDER TERRAFORM VERSIONS with port appended
# # COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
# output "instances" {
#     #value = {for i in module.compute.instance : i.tags.Name => i.public_ip}
#     # this will access the Name tag from compute/main.tf in the resource aws_instance.aws2_node and map it to its respective public_ip address
    
#     # append port syntax
#     value = {for i in module.compute.instance : i.tags.Name => "${i.public_ip}:${module.compute.instance_port}"}
#     # note instance_port was added as output in compute/outputs.tf and define accordingly. This is the target group attachment port used on the
#     # individual EC nodes in the target group backend.
#     # Note the port is the same across all instances so no need to index it with "i"

#     # NOTE in older terraform versions, since we are outputting everything from the compute aws_instance and using in root/outputs.tf
#     # to display in terminal, this throws and error and requires the following line here (and in compute/outputs.tf) to avoid the error:
    
#     sensitive = true
    
#     # in later and current terraform version these sensitive output values are automatically tagged and this line is not required!!!
    
    
# }



#LATEST TERRAFORM VERSION with port appended
# COMMENT modify in both root/outputs.tf and here in compute/outputs.tf
output "instances" {
    #value = {for i in module.compute.instance : i.tags.Name => i.public_ip}
    # this will access the Name tag from compute/main.tf in the resource aws_instance.aws2_node and map it to its respective public_ip address
    
     # append port syntax
    value = {for i in module.compute.instance : i.tags.Name => "${i.public_ip}:${module.compute.instance_port}"}
    # note instance_port was added as output in compute/outputs.tf and define accordingly. This is the target group attachment port used on the
    # individual EC nodes in the target group backend.
    # Note the port is the same across all instances so no need to index it with "i"
}


# Add the KUBECONFIG line to the outputs above so that the kubeconfig yaml files will be displayed in the output when
# doing a terraform apply
# Must iternate through all EC2 instances since there is one .yaml kubeconfig file created for each EC2 instance
output "kubeconfig" {
    #value = [for i in module.compute.instance : "export KUBECONFIG=../k3s-${i.tags.Name}.yaml"]
    # this is done for each instance
    
    # revise the path above and make it absolute so that we do not have to run this from the project directory. We can 
    # run it in any new terminal.
    value = [for i in module.compute.instance : "export KUBECONFIG=/home/ubuntu/environment/k3s-${i.tags.Name}.yaml"]
    
    #sensitive = true
    # Note: as with the instances public_ip and port outputs above, in newer terraform version we do not need the sensitive true commmand
    # the output will be natively displayed with terraform apply simlar to the pubic_ip and port on the instances
    
    # in OLDER terraform versions with the senstive = true need JQ o see the output:
    # terraform output -json | jq ‘.”kubeconfig”.”value”’   to see the kubeconfig values
}