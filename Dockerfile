FROM archlinux:latest

# Dev Container metadata
LABEL devcontainer.metadata='{ \
  "id": "mcp-devops", \
  "version": "1.0.0", \
  "name": "MCP DevOps Development Container", \
  "description": "Wayland desktop with KRDC-compatible VNC for DevOps workflows" \
}'

# Project metadata
LABEL org.opencontainers.image.title="MCP DevOps" \
      org.opencontainers.image.description="Development container for MCP DevOps" \
      org.opencontainers.image.vendor="MCP DevOps Team"

# Arguments for UID/GID mapping
ARG USER_UID=1000
ARG USER_GID=1000

# Install s6-overlay
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/*.tar.xz

# System packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    sudo \
    sway \
    wayvnc \
    xorg-xwayland \
    mesa \
    ttf-liberation \
    foot \
    just \
    neovim \
    openssh \
    rsync \
    wayland-utils \
    net-tools \
    iproute2 \
    shadow

# Create jovian user with specific UID/GID for proper workspace mapping
RUN groupadd --gid ${USER_GID} jovian && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash jovian && \
    usermod -aG wheel jovian && \
    echo "jovian ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/jovian && \
    chmod 0440 /etc/sudoers.d/jovian

# Create workspace with proper ownership
RUN mkdir -p /workspace && \
    chown ${USER_UID}:${USER_GID} /workspace && \
    chmod 755 /workspace

# Install yay for AUR packages
USER jovian
WORKDIR /tmp
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm && \
    cd .. && rm -rf yay

# Install Chrome from AUR
RUN yay -S --noconfirm google-chrome

USER root

# Configure runtime directories
RUN mkdir -p /home/jovian/.config/wayvnc \
             /home/jovian/.config/sway \
             /tmp/runtime-jovian && \
    chown -R ${USER_UID}:${USER_GID} /home/jovian/.config && \
    chown ${USER_UID}:${USER_GID} /tmp/runtime-jovian && \
    chmod 700 /tmp/runtime-jovian

# Setup s6 service structure
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
             /etc/s6-overlay/s6-rc.d/sway/dependencies.d \
             /etc/s6-overlay/s6-rc.d/wayvnc/dependencies.d

# Copy s6 service configurations
COPY config/s6/workspace-fix /etc/s6-overlay/s6-rc.d/workspace-fix
COPY config/s6/sway /etc/s6-overlay/s6-rc.d/sway
COPY config/s6/wayvnc /etc/s6-overlay/s6-rc.d/wayvnc

# Set execute permissions for s6 service scripts
RUN chmod +x /etc/s6-overlay/s6-rc.d/workspace-fix/up \
             /etc/s6-overlay/s6-rc.d/sway/run \
             /etc/s6-overlay/s6-rc.d/wayvnc/run

# Configure s6 service dependencies
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/workspace-fix \
          /etc/s6-overlay/s6-rc.d/user/contents.d/sway \
          /etc/s6-overlay/s6-rc.d/user/contents.d/wayvnc \
          /etc/s6-overlay/s6-rc.d/sway/dependencies.d/workspace-fix \
          /etc/s6-overlay/s6-rc.d/wayvnc/dependencies.d/sway

# Copy Sway configuration
COPY config/sway/config /home/jovian/.config/sway/config
RUN chown ${USER_UID}:${USER_GID} /home/jovian/.config/sway/config

# Copy wayvnc configuration
COPY config/wayvnc/config /home/jovian/.config/wayvnc/config
RUN chown ${USER_UID}:${USER_GID} /home/jovian/.config/wayvnc/config

# Copy and setup entrypoint script
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Environment
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=30000 \
    S6_VERBOSITY=2 \
    S6_KEEP_ENV=1 \
    S6_FIX_ATTRS_HIDDEN=1 \
    DISPLAY_WIDTH=1920 \
    DISPLAY_HEIGHT=1080 \
    PROJECT_NAME=mcp-devops \
    USER=jovian

# Set working directory
WORKDIR /workspace

# VNC port
EXPOSE 5900

# Volume for persistent data
VOLUME ["/workspace", "/home/jovian"]

# Entry point with permission fix
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "/init"]