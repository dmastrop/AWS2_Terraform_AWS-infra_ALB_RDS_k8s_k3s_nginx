This project creates the AWS infra. VPC, subnets, terraform compute, networking and database modules, RDS, Application Load Balancer, 
installation of rancher k3s on control nodes and a test nginx pod deployment to both k3 nodes. Terraform output of kubeconfig yaml,
dns ALB address and ip addresses and port of the nodes as well. Local remote provisioners are used to fetch the k8s kubeconfig as a yaml 
file for local Cloud9 k8s provisioning of the cluster. Userdata block is used to install the rancher k3s onto the nodes. 
The k3s installation will be installed onto a backend RDS database that is shared between the control nodes. 
A test deployment of nginx is installed to both pods. The ALB is configured with port 80 and public dns and the backend target 
and target group and target group attachments to the appropriate container exposed ports (8000 in this simple example). 
The security groups for public and private (db) subnets are created and access is given to local PC subnet and to Cloud9 
for extensive testing of the deployment, SSH access, and kubeconfig control access (6443)
Terraform destroy will remove the local kubeconfig yaml files from the Cloud9 project workspace.
As noted in the k8s counterpart project to this project, the control kubeconfig file is shared with the k8s project via the terraform
remote datasources block in k8s project root/datasources.tf
The nodes had to be upgraded to t3.small for stablity issues.