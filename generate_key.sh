#!/bin/bash

# Script to generate SSH key pair for Ansible if it doesn't exist

KEY_PATH="${HOME}/.ssh/ansible.pem"
PUB_KEY_PATH="${HOME}/.ssh/ansible.pub"
PUB_KEY_PATH_ALT="${HOME}/.ssh/ansible.pem.pub"

echo "Checking for SSH key pair..."

# Check for both possible public key locations
if [ -f "$KEY_PATH" ] && ([ -f "$PUB_KEY_PATH" ] || [ -f "$PUB_KEY_PATH_ALT" ]); then
    echo "✓ SSH key pair already exists at $KEY_PATH"
    
    # Standardize the public key name
    if [ -f "$PUB_KEY_PATH_ALT" ] && [ ! -f "$PUB_KEY_PATH" ]; then
        echo "  Renaming public key to standard location..."
        cp "$PUB_KEY_PATH_ALT" "$PUB_KEY_PATH"
        echo "✓ Public key copied to $PUB_KEY_PATH"
    fi
    
    echo "✓ Public key found at $PUB_KEY_PATH"
else
    echo "SSH key pair not found. Generating new key pair..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "${HOME}/.ssh"
    
    # Generate SSH key pair
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "ansible-automation-key"
    
    if [ $? -eq 0 ]; then
        # Rename .pem.pub to .pub if needed
        if [ -f "$PUB_KEY_PATH_ALT" ] && [ ! -f "$PUB_KEY_PATH" ]; then
            cp "$PUB_KEY_PATH_ALT" "$PUB_KEY_PATH"
        fi
        
        echo "✓ SSH key pair generated successfully!"
        echo "  Private key: $KEY_PATH"
        echo "  Public key: $PUB_KEY_PATH"
        
        # Set proper permissions
        chmod 600 "$KEY_PATH"
        if [ -f "$PUB_KEY_PATH" ]; then
            chmod 644 "$PUB_KEY_PATH"
        fi
        if [ -f "$PUB_KEY_PATH_ALT" ]; then
            chmod 644 "$PUB_KEY_PATH_ALT"
        fi
        
        echo "✓ Permissions set correctly"
    else
        echo "✗ Failed to generate SSH key pair"
        exit 1
    fi
fi

# Display public key fingerprint
echo ""
echo "Public key fingerprint:"
if [ -f "$PUB_KEY_PATH" ]; then
    ssh-keygen -lf "$PUB_KEY_PATH"
elif [ -f "$PUB_KEY_PATH_ALT" ]; then
    ssh-keygen -lf "$PUB_KEY_PATH_ALT"
fi

echo ""
echo "Key pair is ready for Terraform deployment!"
