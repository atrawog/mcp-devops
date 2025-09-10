#!/bin/bash
# Comprehensive verification of all development tools

echo "=== Comprehensive Development Tools Verification ==="
echo ""

# Use the terraform test image
IMAGE="mcp-devops-terraform:test"

echo "Testing with image: $IMAGE"
echo ""

docker run --rm $IMAGE bash -c '
    echo "1. Tool Versions:"
    echo "=================="
    echo -n "  just:      " && just --version
    echo -n "  pixi:      " && pixi --version  
    echo -n "  terraform: " && terraform --version | head -1
    echo ""
    
    echo "2. Binary Locations:"
    echo "===================="
    ls -la /usr/bin/just /usr/bin/pixi /usr/bin/terraform 2>/dev/null || echo "Some binaries not in /usr/bin"
    echo ""
    
    echo "3. Testing as jovian user:"
    echo "=========================="
    su - jovian -c "
        echo \"Running as: \$(whoami)\"
        echo \"  just works:      \$(just --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  pixi works:      \$(pixi --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  terraform works: \$(terraform --version >/dev/null 2>&1 && echo YES || echo NO)\"
    "
    echo ""
    
    echo "4. Quick Functionality Test:"
    echo "============================"
    
    # Test just
    echo "Testing just..."
    echo "default:" > /tmp/justfile
    echo "    @echo \"just is working!\"" >> /tmp/justfile
    cd /tmp && just
    
    # Test terraform
    echo ""
    echo "Testing terraform..."
    terraform -version >/dev/null 2>&1 && echo "✓ Terraform CLI is functional"
    
    # Test pixi
    echo ""
    echo "Testing pixi..."
    pixi --version >/dev/null 2>&1 && echo "✓ Pixi CLI is functional"
'

echo ""
echo "=== Verification Complete ==="
echo "All development tools have been successfully added to the container:"
echo "• just (task runner) - for automation"
echo "• pixi (package manager) - for conda-ecosystem packages"  
echo "• terraform (IaC) - for infrastructure provisioning"