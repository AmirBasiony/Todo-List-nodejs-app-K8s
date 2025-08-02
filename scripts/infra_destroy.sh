#!/bin/bash

# Define the Terraform directory
TERRAFORM_DIR="../terraform"

# Function to display section header
function section_header {
  echo "*******************************************************************************"
  echo "$1"
  echo "*******************************************************************************"
}

# Destroy infrastructure
section_header "*******************       Destroy Infrastructure      *************************"
cd $TERRAFORM_DIR
terraform destroy -auto-approve
