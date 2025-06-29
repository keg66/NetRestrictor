#!/bin/bash

# Network Restriction Test Script for NetRestrictor

CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: config.json not found!"
    exit 1
fi

# Load configuration
ALLOWED_IP=$(jq -r '.allowed_connections.ip' $CONFIG_FILE)
ALLOWED_PORT=$(jq -r '.allowed_connections.port' $CONFIG_FILE)

echo "=== NetRestrictor Network Test ==="
echo "Allowed IP: $ALLOWED_IP"
echo "Allowed Port: $ALLOWED_PORT"
echo

# Test 1: Check if container is running
echo "Test 1: Container Status"
if docker ps | grep -q netrestrictor; then
    echo "✓ NetRestrictor container is running"
else
    echo "✗ NetRestrictor container is not running"
    echo "Please start with: docker-compose up -d"
    exit 1
fi
echo

# Test 2: Test allowed connection
echo "Test 2: Testing Allowed Connection"
echo "Testing connection to $ALLOWED_IP:$ALLOWED_PORT..."
docker exec netrestrictor curl -m 5 --connect-timeout 5 -s "http://$ALLOWED_IP:$ALLOWED_PORT" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Connection to allowed IP:PORT successful"
else
    echo "⚠ Connection to allowed IP:PORT failed (may be expected if target is not accessible)"
fi
echo

# Test 3: Test blocked connection
echo "Test 3: Testing Blocked Connection"
echo "Testing connection to google.com:80 (should be blocked)..."
docker exec netrestrictor curl -m 5 --connect-timeout 5 -s "http://google.com:80" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✗ Connection to blocked site succeeded (FIREWALL NOT WORKING!)"
else
    echo "✓ Connection to blocked site failed (firewall working correctly)"
fi
echo

# Test 4: Check iptables rules
echo "Test 4: Checking iptables rules"
echo "Current INPUT rules:"
docker exec netrestrictor iptables -L INPUT -n --line-numbers
echo
echo "Current OUTPUT rules:"
docker exec netrestrictor iptables -L OUTPUT -n --line-numbers
echo

# Test 5: Check logs (if available)
echo "Test 5: Recent Container Logs"
docker logs --tail 10 netrestrictor
echo

echo "=== Test Complete ==="