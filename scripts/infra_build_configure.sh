#!/bin/bash

# Define variables

TERRAFORM_DIR="../terraform/"
ANSIBLE_DIR="../Ansible_Rules/"
INFRA_DIAGRAM_DIR="../infrastructure_diagram"
SSH_KEY="../terraform/todo-app-ssh-key.pem"
# Function to display section header
function section_header {
  echo "*******************************************************************************"
  echo "$1"
  echo "*******************************************************************************"
}

# Navigate to Terraform directory
cd $TERRAFORM_DIR

# Build infrastructure
section_header "*********************    Building the infrastructure     **********************"
terraform init #-reconfigure
terraform validate
terraform apply -auto-approve -refresh=false

mkdir -p "$INFRA_DIAGRAM_DIR"
terraform graph | dot -Tpng > "$INFRA_DIAGRAM_DIR/[Terraform]_Infra_In-Depth.png"

# Fetch values from Terraform outputs
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)
AWS_REGION=$(terraform output -raw aws_region)

# Display key info
section_header "*******************   Infrastructure Deployed Successfully   *******************"
echo           "*******************            $EC2_PUBLIC_IP            *******************"
echo           "*******************     AWS Region: $AWS_REGION     *******************"
echo           "*******************************************************************************"

if [[ -z "$EC2_PUBLIC_IP" || -z "$AWS_REGION" ]]; then
  echo "ERROR: One or more required Terraform outputs are missing."
  exit 1
fi


# Navigate to Ansible directory
cd "$ANSIBLE_DIR" || exit 1




section_header "**********************    Generating Ansible inventory     ********************"
# Prepare inventory.ini
chmod 600 $SSH_KEY  # Secures the SSH private key
touch inventory.ini && chmod 755 inventory.ini
echo -e "[remote_target]\n$EC2_PUBLIC_IP" > inventory.ini
cat inventory.ini

section_header "**********************    Running ansible rules     ***************************"
# Run the Ansible playbook 
ansible-playbook -i inventory.ini --private-key $SSH_KEY  EC2_server.yaml

section_header "*********** Application EC2 server is configured successfully     *************"

cd ../

section_header "***********     Push the changed to and trigger the pipeline      *************"

git add .
git commit -m "$1"
git push 
