#!/bin/bash
# Entrypoint script for MCP DevOps container

# Run Docker GID sync if socket is mounted
if [ -e /var/run/docker.sock ]; then
    echo "Docker socket detected, syncing permissions..."
    /usr/local/bin/sync-docker-gid.sh
fi

# Execute the main command (usually /init for s6-overlay)
exec "$@"