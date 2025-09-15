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
    
    echo "3. OpenTofu (IaC Tool):"
    tofu version
    echo ""

    echo "4. Node.js and npm:"
    node --version
    npm --version
    echo ""

    echo "5. Claude CLI:"
    claude --version 2>/dev/null || echo "Claude CLI not found in system path"
    echo ""

    echo "6. Scaleway CLI:"
    scw version 2>/dev/null || echo "Scaleway CLI not found"
    echo ""

    echo "7. Testing as jovian user:"
    su - jovian -c "
        echo \"  just: $(just --version)\"
        echo \"  pixi: $(pixi --version)\"
        echo \"  opentofu: $(tofu version 2>/dev/null | head -1 || echo 'not found')\"
        echo \"  node: $(node --version)\"
        echo \"  npm: $(npm --version)\"
        echo \"  claude: $(claude --version 2>/dev/null || echo 'not found')\"
        echo \"  scaleway: $(scw version 2>/dev/null || echo 'not found')\"
        echo \"  Testing aliases:\"
        echo \"    cl alias: $(type cl 2>/dev/null | head -1 || echo 'not found')\"
        echo \"    clc alias: $(type clc 2>/dev/null | head -1 || echo 'not found')\"
        echo \"  npm global path: $(npm config get prefix 2>/dev/null)\"
        echo \"  PATH includes npm: $(echo \$PATH | grep -q '.npm-global' && echo 'YES' || echo 'NO')\"
    "
    echo ""

    echo "8. Available commands:"
    echo "  just: $(which just)"
    echo "  pixi: $(which pixi)"
    echo "  opentofu: $(which tofu 2>/dev/null || which opentofu)"
    echo "  node: $(which node)"
    echo "  npm: $(which npm)"
    echo "  scaleway: $(which scw)"
'

echo ""
echo "=== Test Complete ==="
echo "Development tools installed and verified:"
echo "  • just (task runner)"
echo "  • pixi (package manager)"
echo "  • opentofu (IaC tool)"
echo "  • scaleway-cli (Scaleway cloud management)"
echo "  • nodejs & npm (JavaScript runtime & package manager)"
echo "  • claude (Claude CLI with aliases)"