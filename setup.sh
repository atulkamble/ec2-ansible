#!/bin/bash

# Complete setup script for Ansible Terraform infrastructure

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "================================================"
echo "  AWS Ansible Infrastructure Setup"
echo "================================================"
echo ""

# Step 1: Generate SSH key pair if needed
echo "Step 1: Checking SSH Key Pair..."
echo "----------------------------------------"
if [ -f "./generate_key.sh" ]; then
    chmod +x ./generate_key.sh
    ./generate_key.sh
else
    echo "Error: generate_key.sh not found"
    exit 1
fi
echo ""

# Step 2: Create terraform.tfvars if it doesn't exist
echo "Step 2: Configuring Terraform Variables..."
echo "----------------------------------------"
if [ ! -f "terraform.tfvars" ]; then
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo "✓ Created terraform.tfvars from example"
    else
        echo "Creating terraform.tfvars..."
        cat > terraform.tfvars <<EOF
# AWS Configuration
aws_region = "us-east-1"

# SSH Key Paths
public_key_path  = "~/.ssh/ansible.pub"
private_key_path = "~/.ssh/ansible.pem"
EOF
        echo "✓ Created terraform.tfvars"
    fi
else
    echo "✓ terraform.tfvars already exists"
fi
echo ""

# Step 3: Check if key exists in AWS
echo "Step 3: Checking AWS Key Pair Status..."
echo "----------------------------------------"
if [ -f "./check_and_import_key.sh" ]; then
    chmod +x ./check_and_import_key.sh
    
    # Get AWS region from terraform.tfvars
    AWS_REGION=$(grep 'aws_region' terraform.tfvars | cut -d'=' -f2 | tr -d ' "' | head -1)
    if [ -z "$AWS_REGION" ]; then
        AWS_REGION="us-east-1"
    fi
    
    ./check_and_import_key.sh "$AWS_REGION"
else
    echo "Warning: check_and_import_key.sh not found, skipping AWS check"
fi
echo ""

# Step 4: Initialize Terraform
echo "Step 4: Initializing Terraform..."
echo "----------------------------------------"
if terraform init; then
    echo "✓ Terraform initialized successfully"
else
    echo "✗ Terraform initialization failed"
    exit 1
fi
echo ""

# Step 5: Validate Terraform configuration
echo "Step 5: Validating Terraform Configuration..."
echo "----------------------------------------"
if terraform validate; then
    echo "✓ Terraform configuration is valid"
else
    echo "✗ Terraform configuration validation failed"
    exit 1
fi
echo ""

# Step 6: Show what will be created
echo "Step 6: Terraform Plan Preview..."
echo "----------------------------------------"
echo "Running terraform plan to show what will be created..."
echo ""
terraform plan
echo ""

# Step 7: Prompt for deployment
echo "================================================"
echo "Setup Complete! Ready to deploy."
echo "================================================"
echo ""
echo "To deploy the infrastructure, run:"
echo "  terraform apply"
echo ""
echo "Or run this script with auto-approve:"
echo "  terraform apply -auto-approve"
echo ""
echo "After deployment, get connection details with:"
echo "  terraform output"
echo ""

# Optional: Ask if user wants to deploy now
read -p "Do you want to deploy now? (yes/no): " -r
echo ""
if [[ $REPLY =~ ^[Yy]es$ ]]; then
    echo "Deploying infrastructure..."
    terraform apply
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "================================================"
        echo "  Deployment Successful!"
        echo "================================================"
        echo ""
        terraform output
        echo ""
        echo "To connect to your Ansible server:"
        terraform output -raw ssh_command_ansible_server
        echo ""
    else
        echo "Deployment failed. Please check the errors above."
        exit 1
    fi
else
    echo "Skipping deployment. Run 'terraform apply' when ready."
fi
