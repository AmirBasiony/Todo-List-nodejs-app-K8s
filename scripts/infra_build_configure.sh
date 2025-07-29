#!/bin/bash

# Define variables

TERRAFORM_DIR="../terraform/"
ANSIBLE_DIR="../Ansible_Rules/"
INFRA_DIAGRAM_DIR="../infrastructure_diagram"

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
PRIVATE_ID_1=$(terraform output -raw web_server_private1_id)
PRIVATE_ID_2=$(terraform output -raw web_server_private2_id)
SSM_BUCKET=$(terraform output -raw ansible_ssm_bucket_name)
AWS_REGION=$(terraform output -raw aws_region)
SSM_TIMEOUT="60"

# Display key info
section_header "*******************   Infrastructure Deployed Successfully   *******************"
echo           "*******************           Private EC2 Instance IDs           *******************"
echo           "*******************            $PRIVATE_ID_1            *******************"
echo           "*******************            $PRIVATE_ID_2            *******************"
echo           "*******************    SSM Bucket: $SSM_BUCKET    *******************"
echo           "*******************     AWS Region: $AWS_REGION     *******************"
echo           "*******************************************************************************"

if [[ -z "$PRIVATE_ID_1" || -z "$PRIVATE_ID_2" || -z "$AWS_REGION" ]]; then
  echo "ERROR: One or more required Terraform outputs are missing."
  exit 1
fi


# Navigate to Ansible directory
cd "$ANSIBLE_DIR" || exit 1

# Prepare inventory.ini
section_header "**********************    Generating Ansible inventory     ********************"


INVENTORY_FILE="inventory.ini"
CONFIG_FILE="ansible.cfg"
touch "$INVENTORY_FILE" && chmod 755 "$INVENTORY_FILE"


# Write private_ec2 inventory
{
  echo "[private_ec2]"
  echo "$PRIVATE_ID_1"
  echo "$PRIVATE_ID_2"
  echo
  echo "[private_ec2:vars]"
  echo "ansible_connection=amazon.aws.aws_ssm"
  echo "ansible_region=$AWS_REGION"
  echo "ansible_aws_ssm_bucket_name=$SSM_BUCKET"
  echo "ansible_aws_ssm_timeout=$SSM_TIMEOUT"
} > "$INVENTORY_FILE"

cat $INVENTORY_FILE
# Generate ansible.cfg

section_header "**********************    Generating Ansible config     **********************"
cat <<EOF > $CONFIG_FILE
[defaults]
inventory = inventory.ini
remote_tmp = /tmp/.ansible/tmp
host_key_checking = False
timeout = 60
collections_path = ~/.ansible/collections:/usr/share/ansible/collections
EOF

cat $CONFIG_FILE

section_header "**********************    Run the Ansible playbook     **********************"
# Run the Ansible playbook 
ansible-playbook EC2_server.yaml # -vvv

section_header "*********** Application EC2 server is configured successfully     *************"
                
cd ../

section_header "***********     Push the changed to and trigger the pipeline      *************"

git add .
git commit -m "$1"
git push 
