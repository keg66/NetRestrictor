#!/bin/bash

# Load configuration
CONFIG_FILE="/app/config.json"
ALLOWED_IP=$(jq -r '.allowed_connections.ip' $CONFIG_FILE)
ALLOWED_PORT=$(jq -r '.allowed_connections.port' $CONFIG_FILE)
PROTOCOL=$(jq -r '.allowed_connections.protocol' $CONFIG_FILE)
LOG_DROPPED=$(jq -r '.rules.log_dropped' $CONFIG_FILE)

echo "Setting up firewall rules..."
echo "Allowed IP: $ALLOWED_IP"
echo "Allowed Port: $ALLOWED_PORT"
echo "Protocol: $PROTOCOL"

# Clear existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow INPUT from specified IP and PORT only
iptables -A INPUT -p $PROTOCOL -s $ALLOWED_IP --sport $ALLOWED_PORT -j ACCEPT

# Allow OUTPUT to specified IP and PORT only
iptables -A OUTPUT -p $PROTOCOL -d $ALLOWED_IP --dport $ALLOWED_PORT -j ACCEPT

# Log dropped packets if enabled
if [ "$LOG_DROPPED" = "true" ]; then
    iptables -A INPUT -j LOG --log-prefix "NETRESTRICTOR-INPUT-DROP: "
    iptables -A OUTPUT -j LOG --log-prefix "NETRESTRICTOR-OUTPUT-DROP: "
fi

# Drop everything else
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP

echo "Firewall rules applied successfully!"

# Display current rules
echo "Current iptables rules:"
iptables -L -n -v