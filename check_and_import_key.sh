#!/bin/bash

# Script to check if key pair exists in AWS and import if needed

KEY_NAME="ansible"
AWS_REGION="${1:-us-east-1}"
PUBLIC_KEY_PATH="${HOME}/.ssh/ansible.pub"

echo "Checking AWS key pair status..."
echo "Region: $AWS_REGION"
echo "Key Name: $KEY_NAME"
echo ""

# Check if key pair exists in AWS
KEY_EXISTS=$(aws ec2 describe-key-pairs \
    --region "$AWS_REGION" \
    --key-names "$KEY_NAME" \
    --query 'KeyPairs[0].KeyName' \
    --output text 2>/dev/null)

if [ "$KEY_EXISTS" == "$KEY_NAME" ]; then
    echo "✓ Key pair '$KEY_NAME' already exists in AWS"
    echo "  Terraform will use the existing key pair"
    echo ""
    echo "To import into Terraform state (if not already imported):"
    echo "  terraform import aws_key_pair.ansible_key $KEY_NAME"
else
    echo "✗ Key pair '$KEY_NAME' does not exist in AWS"
    echo "  Terraform will create it during apply"
    
    # Check if local public key exists
    if [ -f "$PUBLIC_KEY_PATH" ]; then
        echo ""
        echo "Local public key found: $PUBLIC_KEY_PATH"
        echo "You can manually import it to AWS with:"
        echo "  aws ec2 import-key-pair --region $AWS_REGION --key-name $KEY_NAME --public-key-material fileb://$PUBLIC_KEY_PATH"
    else
        echo ""
        echo "⚠ Warning: Public key not found at $PUBLIC_KEY_PATH"
        echo "Run ./generate_key.sh first to generate the key pair"
    fi
fi

echo ""
