#!/bin/bash

# Script to check if a key pair exists in AWS
# Usage: ./check_keypair.sh [key-pair-name] [aws-region]

set -e

# Default values
KEY_NAME=${1:-"ansible"}
AWS_REGION=${2:-"us-east-1"}

echo "🔍 Checking for key pair '$KEY_NAME' in region '$AWS_REGION'..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS is configured
if ! aws configure list &> /dev/null; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if key pair exists
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo "✅ Key pair '$KEY_NAME' exists in AWS region '$AWS_REGION'"
    
    # Get key pair details
    KEY_INFO=$(aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" --query 'KeyPairs[0]' --output json)
    KEY_TYPE=$(echo "$KEY_INFO" | jq -r '.KeyType // "rsa"')
    FINGERPRINT=$(echo "$KEY_INFO" | jq -r '.KeyFingerprint')
    
    echo "   - Key Type: $KEY_TYPE"
    echo "   - Fingerprint: $FINGERPRINT"
    echo ""
    echo "💡 To use this existing key pair, set in your terraform.tfvars:"
    echo "   use_existing_key_pair = true"
    echo "   create_key_pair = false"
    echo "   key_pair_name = \"$KEY_NAME\""
    echo ""
else
    echo "❌ Key pair '$KEY_NAME' does not exist in AWS region '$AWS_REGION'"
    echo ""
    echo "💡 Options:"
    echo "   1. Create a new key pair with Terraform (default behavior)"
    echo "   2. Create the key pair manually in AWS console"
    echo "   3. Use a different key pair name"
    echo ""
    echo "📝 To create with Terraform, set in your terraform.tfvars:"
    echo "   use_existing_key_pair = false"
    echo "   create_key_pair = true"
    echo "   key_pair_name = \"$KEY_NAME\""
fi

echo ""
echo "🚀 Usage examples:"
echo "   ./check_keypair.sh                    # Check for 'ansible' key in us-east-1"
echo "   ./check_keypair.sh my-key             # Check for 'my-key' in us-east-1"
echo "   ./check_keypair.sh my-key us-west-2   # Check for 'my-key' in us-west-2"