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

# Determine test mode
if [ "$ALLOWED_PORT" = "null" ] || [ -z "$ALLOWED_PORT" ] || [ "$ALLOWED_PORT" = "" ]; then
    TEST_MODE="all_ports"
    echo "Test Mode: All ports allowed for specified IP"
else
    TEST_MODE="specific_port"
    echo "Test Mode: Specific port ($ALLOWED_PORT) only"
fi
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
if [ "$TEST_MODE" = "all_ports" ]; then
    echo "Testing connection to $ALLOWED_IP (all ports allowed)..."
    # Test multiple ports when all ports are allowed
    for port in 80 443 8080; do
        echo "  Testing port $port..."
        docker exec netrestrictor curl -m 3 --connect-timeout 3 -s "http://$ALLOWED_IP:$port" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "  ✓ Connection to $ALLOWED_IP:$port successful"
        else
            echo "  ⚠ Connection to $ALLOWED_IP:$port failed (may be expected if target is not accessible)"
        fi
    done
else
    echo "Testing connection to $ALLOWED_IP:$ALLOWED_PORT (specific port only)..."
    docker exec netrestrictor curl -m 5 --connect-timeout 5 -s "http://$ALLOWED_IP:$ALLOWED_PORT" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Connection to allowed IP:PORT successful"
    else
        echo "⚠ Connection to allowed IP:PORT failed (may be expected if target is not accessible)"
    fi
    
    # Test blocked port when specific port is configured
    if [ "$ALLOWED_PORT" != "443" ]; then
        echo "Testing blocked port 443 on same IP (should be blocked)..."
        docker exec netrestrictor curl -m 3 --connect-timeout 3 -s "https://$ALLOWED_IP:443" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✗ Connection to blocked port succeeded (FIREWALL NOT WORKING!)"
        else
            echo "✓ Connection to blocked port failed (firewall working correctly)"
        fi
    fi
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

# Test 4.5: Verify rule configuration matches test mode
echo "Test 4.5: Rule Configuration Verification"
if [ "$TEST_MODE" = "all_ports" ]; then
    echo "Verifying all-ports configuration..."
    INPUT_RULE=$(docker exec netrestrictor iptables -L INPUT -n | grep "$ALLOWED_IP" | grep -v "dpt\|spt")
    OUTPUT_RULE=$(docker exec netrestrictor iptables -L OUTPUT -n | grep "$ALLOWED_IP" | grep -v "dpt\|spt")
    if [ -n "$INPUT_RULE" ] && [ -n "$OUTPUT_RULE" ]; then
        echo "✓ Rules correctly configured for all ports"
    else
        echo "✗ Rules incorrectly configured - port restrictions found when all ports should be allowed"
    fi
else
    echo "Verifying specific-port configuration..."
    INPUT_RULE=$(docker exec netrestrictor iptables -L INPUT -n | grep "$ALLOWED_IP" | grep "spt:$ALLOWED_PORT")
    OUTPUT_RULE=$(docker exec netrestrictor iptables -L OUTPUT -n | grep "$ALLOWED_IP" | grep "dpt:$ALLOWED_PORT")
    if [ -n "$INPUT_RULE" ] && [ -n "$OUTPUT_RULE" ]; then
        echo "✓ Rules correctly configured for port $ALLOWED_PORT only"
    else
        echo "✗ Rules incorrectly configured - port $ALLOWED_PORT restriction not found"
    fi
fi
echo

# Test 5: Check logs (if available)
echo "Test 5: Recent Container Logs"
docker logs --tail 10 netrestrictor
echo

echo "=== Test Complete ==="