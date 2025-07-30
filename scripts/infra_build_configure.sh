#!/bin/bash
set -e  # Exit on error

# Define directories
SCRIPTS_DIR="../scripts"
TERRAFORM_DIR="../terraform/"
ANSIBLE_DIR="../Ansible_Rules/"
INFRA_DIAGRAM_DIR="../infrastructure_diagram"
SSH_KEY="${TERRAFORM_DIR}/todo-app-ssh-key.pem"

# Section header display
function section_header {
  echo "*******************************************************************************"
  echo "$1"
  echo "*******************************************************************************"
}

# Navigate to Terraform directory
cd "$TERRAFORM_DIR" || { echo "ERROR: Terraform directory not found!"; exit 1; }

# Build infrastructure
section_header "*********************    Building the infrastructure     **********************"
terraform init #-reconfigure
terraform validate
terraform apply -auto-approve -refresh=false

# Generate infrastructure diagram
mkdir -p "$INFRA_DIAGRAM_DIR"
terraform graph | dot -Tpng > "$INFRA_DIAGRAM_DIR/[Terraform]_Infra_In-Depth.png"

# Get public IP
EC2_PUBLIC_IP=$(terraform output -raw ec2_public_ip)

if [[ -z "$EC2_PUBLIC_IP" ]]; then
  echo "ERROR: EC2 public IP not found in Terraform outputs."
  exit 1
fi

# Show result
section_header "*******************   Infrastructure Deployed Successfully   *******************"
echo  "Todo List App Public IP:  $EC2_PUBLIC_IP"
echo

# Navigate to Ansible directory
cd "$ANSIBLE_DIR" || { echo "ERROR: Ansible directory not found!"; exit 1; }

# Generate inventory file
section_header "**********************    Generating Ansible inventory     ********************"
chmod 600 "$SSH_KEY"  # Secures the SSH private key
echo -e "[remote_target]\n$EC2_PUBLIC_IP" > inventory.ini
chmod 644 inventory.ini
cat inventory.ini

# Run Ansible (optional - uncomment if needed)
section_header "**********************    Running ansible rules     ***************************"
ansible-playbook -i inventory.ini --private-key "$SSH_KEY" EC2_server.yaml 

# Confirm EC2 is ready
section_header "*********** Application EC2 server is configured successfully     *************"
echo

# Move to scripts dir
cd "$SCRIPTS_DIR" || { echo "ERROR: Scripts directory not found!"; exit 1; }

# SCP and remote execution
scp -i "$SSH_KEY" ../ArgoCD-Apps/application.yaml ubuntu@"$EC2_PUBLIC_IP":~/application.yaml
scp -i "$SSH_KEY" setup_minikube_argocd.sh ubuntu@"$EC2_PUBLIC_IP":~/setup_minikube_argocd.sh
ssh -i "$SSH_KEY" ubuntu@"$EC2_PUBLIC_IP" \
  "chmod +x ~/setup_minikube_argocd.sh && ~/setup_minikube_argocd.sh"

# Return to root project directory
cd ../

# Git push
section_header "************     Push the changes and trigger the pipeline      ***************"
git add .
git commit -m "${1:-"Auto: Infrastructure deployment"}"
git push
