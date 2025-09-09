#!/bin/bash
if [ "$EUID" -eq 0 ]; then
    if [ -n "${USER_UID}" ] && [ -n "${USER_GID}" ]; then
        usermod -u ${USER_UID} jovian 2>/dev/null || true
        groupmod -g ${USER_GID} jovian 2>/dev/null || true
        chown -R ${USER_UID}:${USER_GID} /home/jovian 2>/dev/null || true
        chown -R ${USER_UID}:${USER_GID} /workspace 2>/dev/null || true
    fi
fi
exec "$@"