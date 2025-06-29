# NetRestrictor

A defensive security tool based on Ubuntu 22.04 Docker container that restricts all network communication except to specified IP:PORT combinations.

## Features

- Bidirectional HTTP communication only to specified IP:PORT
- Strict network control using iptables
- Flexible configuration via config file
- Traffic monitoring with logging capabilities

## Usage

### 1. Edit Configuration

Edit `config.json` to set allowed IP:PORT:

```json
{
  "allowed_connections": {
    "ip": "192.168.1.100",
    "port": 80,
    "protocol": "tcp"
  }
}
```

### 2. Start Container

```bash
# Build and start
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 3. Run Tests

```bash
chmod +x test-network.sh
./test-network.sh
```

## File Structure

- `Dockerfile` - Ubuntu 22.04 based container definition
- `config.json` - Communication permission settings
- `setup-firewall.sh` - iptables rules configuration script
- `start.sh` - Container startup script
- `docker-compose.yml` - Container execution configuration
- `test-network.sh` - Network restriction test script

## Important Notes

- Container runs with `privileged: true` (required for iptables operations)
- All communications are strictly restricted
- Loopback communication (127.0.0.1) is permitted