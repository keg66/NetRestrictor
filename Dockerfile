FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    iptables \
    curl \
    jq \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy configuration and scripts
COPY config.json /app/
COPY setup-firewall.sh /app/
COPY start.sh /app/

# Make scripts executable
RUN chmod +x /app/setup-firewall.sh /app/start.sh

# Run with privileged mode required for iptables
CMD ["/app/start.sh"]