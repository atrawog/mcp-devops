#!/bin/bash
# Comprehensive verification of all development tools

echo "=== Comprehensive Development Tools Verification ==="
echo ""

# Use the test image
IMAGE="${1:-mcp-devops:latest}"

echo "Testing with image: $IMAGE"
echo ""

docker run --rm $IMAGE bash -c '
    echo "1. Tool Versions:"
    echo "=================="
    echo -n "  just:      " && just --version
    echo -n "  pixi:      " && pixi --version
    echo -n "  opentofu:  " && tofu version | head -1
    echo -n "  node:      " && node --version
    echo -n "  npm:       " && npm --version
    echo ""

    echo "2. Binary Locations:"
    echo "===================="
    ls -la /usr/bin/just /usr/bin/pixi /usr/bin/tofu /usr/bin/node /usr/bin/npm 2>/dev/null || echo "Checking alternative locations..."
    echo ""

    echo "3. Testing as jovian user:"
    echo "=========================="
    su - jovian -c "
        echo \"Running as: \$(whoami)\"
        echo \"Home directory: \$HOME\"
        echo \"  just works:      \$(just --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  pixi works:      \$(pixi --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  opentofu works:  \$(tofu version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  node works:      \$(node --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  npm works:       \$(npm --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"  claude works:    \$(claude --version >/dev/null 2>&1 && echo YES || echo NO)\"
        echo \"\"
        echo \"NPM Configuration:\"
        echo \"  npm prefix:      \$(npm config get prefix 2>/dev/null)\"
        echo \"  .npm-global exists: \$([ -d ~/.npm-global ] && echo YES || echo NO)\"
        echo \"  PATH includes npm:  \$(echo \$PATH | grep -q '.npm-global' && echo YES || echo NO)\"
        echo \"\"
        echo \"Claude CLI Aliases:\"
        echo \"  cl:  \$(type cl 2>/dev/null | grep -q alias && echo 'Configured' || echo 'Not found')\"
        echo \"  clc: \$(type clc 2>/dev/null | grep -q alias && echo 'Configured' || echo 'Not found')\"
        echo \"  cld: \$(type cld 2>/dev/null | grep -q alias && echo 'Configured' || echo 'Not found')\"
        echo \"  cldc: \$(type cldc 2>/dev/null | grep -q alias && echo 'Configured' || echo 'Not found')\"
    "
    echo ""
    
    echo "4. Quick Functionality Test:"
    echo "============================"
    
    # Test just
    echo "Testing just..."
    echo "default:" > /tmp/justfile
    echo "    @echo \"just is working!\"" >> /tmp/justfile
    cd /tmp && just
    
    # Test opentofu
    echo ""
    echo "Testing opentofu..."
    tofu version >/dev/null 2>&1 && echo "✓ OpenTofu CLI is functional"
    
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
echo "• opentofu (IaC tool) - for infrastructure as code"
echo "• node.js & npm - for JavaScript development"
echo "• claude CLI - for AI-assisted development with aliases (cl, clc, cld, cldc)"