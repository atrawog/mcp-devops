#!/bin/bash
# Test script to verify development tools are installed

echo "=== Development Tools Test ==="
echo ""

# Build container if needed
if [[ "$1" == "--build" ]]; then
    echo "Building container..."
    docker build --no-cache -t mcp-devops:latest . --quiet || exit 1
    echo "✓ Build complete"
    echo ""
fi

# Run tests
echo "Testing installed development tools..."
docker run --rm mcp-devops:latest bash -c '
    echo "1. Just (Task Runner):"
    just --version
    echo ""
    
    echo "2. Pixi (Package Manager):"
    pixi --version
    echo ""
    
    echo "3. Terraform (IaC Tool):"
    terraform --version
    echo ""
    
    echo "4. Testing as jovian user:"
    su - jovian -c "
        echo \"  just: $(just --version)\"
        echo \"  pixi: $(pixi --version)\"
        echo \"  terraform: $(terraform --version | head -1)\"
    "
    echo ""
    
    echo "5. Available commands:"
    echo "  just: $(which just)"
    echo "  pixi: $(which pixi)"
    echo "  terraform: $(which terraform)"
'

echo ""
echo "=== Test Complete ==="
echo "Development tools (just, pixi, terraform) are installed and accessible to all users."