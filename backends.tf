# this is root/backends.tf in AWS2 proect.  This is very simllar in structure to the root/backends.tf file for the 
#k8s workspace/project
# This will push the Cloud9 AWS2 workspace terraform state to the workspace course7-terraform-adv-AWS-dev on terraform cloud
# This state is separate from the k8s workspace project on Cloud9 and terraform cloud
# In this way we can tear down the k8s terraform state without affecting the AWS terraform state.

terraform {
  cloud {
    organization = "course7_terraform_adv_AWS_org"
    # this is my org on terraform.io cloud

    workspaces {
      name = "course7-terraform-adv-AWS-dev"
      # this is my workspace on terraform.io cloud
    }
  }
}