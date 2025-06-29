#!/bin/bash

echo "Starting NetRestrictor container..."

# Validate configuration file
if [ ! -f "/app/config.json" ]; then
    echo "ERROR: Configuration file not found!"
    exit 1
fi

# Validate JSON syntax
if ! jq empty /app/config.json 2>/dev/null; then
    echo "ERROR: Invalid JSON in configuration file!"
    exit 1
fi

# Setup firewall rules
/app/setup-firewall.sh

if [ $? -eq 0 ]; then
    echo "NetRestrictor firewall setup completed successfully!"
    echo "Container is now running with network restrictions active."
    
    # Keep container running
    echo "Monitoring network restrictions... (Press Ctrl+C to stop)"
    while true; do
        sleep 30
        # Optional: Add periodic rule verification here
        echo "$(date): NetRestrictor active - Rules enforced"
    done
else
    echo "ERROR: Failed to setup firewall rules!"
    exit 1
fi