# 🔍 Comprehensive Observability Stack

A complete, production-ready observability stack using Docker Compose with popular monitoring, logging, and tracing tools. Perfect for VPS deployment with nginx reverse proxy and SSL termination.

## 🚀 Features

### Core Components
- **📊 Monitoring**: Prometheus, Grafana, Node Exporter, cAdvisor, Alertmanager
- **📝 Logging**: Loki, Promtail with log aggregation and correlation
- **🔍 Tracing**: Jaeger, OpenTelemetry Collector for distributed tracing
- **💓 Health Monitoring**: Uptime Kuma, Blackbox Exporter
- **🔄 Reverse Proxy**: nginx with SSL termination and load balancing
- **💾 Storage**: PostgreSQL, Redis for data persistence and caching

### Key Benefits
- **🏗️ Production Ready**: SSL/TLS, authentication, rate limiting, security headers
- **📈 Scalable**: Resource limits, horizontal scaling, performance monitoring
- **🛡️ Secure**: Internal networking, authentication, encrypted communications
- **📱 Comprehensive**: System, container, application, and network monitoring
- **🔧 Maintainable**: Log rotation, automated cleanup, health checks

## 🛠️ Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Domain name pointing to your server (required for HTTPS)
- Open ports: 80, 443
- DNS records configured (see Domain Setup section)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd open-observality-final-boss
```

### 2. Domain Setup
Before deploying, you need to configure your domain DNS records:

#### Required DNS Records
```
# Main domain
your-domain.com         A       YOUR_SERVER_IP

# Subdomains for services
monitoring.your-domain.com    A       YOUR_SERVER_IP
status.your-domain.com        A       YOUR_SERVER_IP
prometheus.your-domain.com    A       YOUR_SERVER_IP
jaeger.your-domain.com        A       YOUR_SERVER_IP
loki.your-domain.com          A       YOUR_SERVER_IP

# Optional: Wildcard record (easier management)
*.your-domain.com       A       YOUR_SERVER_IP
```

#### Verify DNS Resolution
```bash
# Test DNS resolution
nslookup your-domain.com
nslookup monitoring.your-domain.com

# Test from your server
ping your-domain.com
```

### 3. Configure Environment
```bash
cp .env .env.local
# Edit .env with your domain and passwords
nano .env
```

**⚠️ Important Configuration**:
- Set `DOMAIN=your-domain.com` (replace with your actual domain)
- Update all passwords (they all contain `change_me`)
- Configure email settings for alerts
- Set up Slack webhook URL if needed

#### Example .env Configuration
```bash
# Domain Configuration
DOMAIN=monitoring.example.com

# Database Configuration
POSTGRES_DB=observability
POSTGRES_USER=observability_user
POSTGRES_PASSWORD=secure_postgres_password_123

# Redis Configuration
REDIS_PASSWORD=secure_redis_password_456

# Grafana Configuration
GRAFANA_ADMIN_PASSWORD=secure_grafana_admin_789

# SSL Configuration
SSL_EMAIL=admin@example.com
CERTBOT_STAGING=false

# Alerting Configuration
ALERT_EMAIL=alerts@example.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### 4. Deploy Stack
```bash
# Automated deployment (recommended)
./start.sh

# Or manual deployment
docker compose up -d
```

The automated script will:
- ✅ Check prerequisites
- ✅ Validate configuration
- ✅ Generate SSL certificates
- ✅ Start all services
- ✅ Display access information

### 5. Access Services

#### Main Dashboard Access
- **Grafana**: https://your-domain.com/grafana/ (admin/your-password)
- **Prometheus**: https://your-domain.com/prometheus/
- **Jaeger**: https://your-domain.com/jaeger/
- **Uptime Kuma**: https://your-domain.com/uptime/
- **Alertmanager**: https://your-domain.com/alertmanager/

#### Subdomain Access (cleaner URLs)
- **Monitoring Dashboard**: https://monitoring.your-domain.com/
- **Status Page**: https://status.your-domain.com/
- **Metrics**: https://prometheus.your-domain.com/
- **Traces**: https://jaeger.your-domain.com/
- **Logs**: https://loki.your-domain.com/

#### Default Credentials
- **Grafana**: admin / [your GRAFANA_ADMIN_PASSWORD]
- **Uptime Kuma**: Set up on first visit
- **Other services**: No authentication required (internal access only)

## 📋 Configuration

### Environment Variables
Key variables in `.env`:
- `DOMAIN`: Your domain name
- `GRAFANA_ADMIN_PASSWORD`: Grafana admin password
- `POSTGRES_PASSWORD`: Database password
- `REDIS_PASSWORD`: Redis password
- `ALERT_EMAIL`: Email for alerts
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications

### SSL/TLS Setup

#### Option 1: Let's Encrypt (Recommended for Production)
```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Stop nginx temporarily
docker compose stop nginx

# Generate certificates for all domains
certbot certonly --standalone -d your-domain.com \
  -d monitoring.your-domain.com \
  -d status.your-domain.com \
  -d prometheus.your-domain.com \
  -d jaeger.your-domain.com \
  -d loki.your-domain.com \
  --email your-email@example.com \
  --agree-tos --no-eff-email

# Copy certificates to nginx volume
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /var/lib/docker/volumes/open-observality-final-boss_nginx_ssl/_data/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /var/lib/docker/volumes/open-observality-final-boss_nginx_ssl/_data/key.pem

# Start nginx
docker compose start nginx
```

#### Option 2: Wildcard Certificate (Advanced)
```bash
# For wildcard certificates (*.your-domain.com)
certbot certonly --manual --preferred-challenges dns \
  -d your-domain.com -d "*.your-domain.com" \
  --email your-email@example.com \
  --agree-tos --no-eff-email

# Follow DNS challenge instructions
# Copy certificates as above
```

#### Option 3: Self-Signed (Development Only)
```bash
# Generated automatically by start.sh
# Or manually:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"
```

#### SSL Certificate Renewal
```bash
# Add to crontab for automatic renewal
0 3 * * * certbot renew --quiet && docker compose restart nginx
```

### Custom Dashboards
Add dashboards to `grafana/dashboards/`:
- `system/`: System monitoring dashboards
- `application/`: Application monitoring dashboards
- `infrastructure/`: Infrastructure dashboards

## 🔧 Management

### Common Commands
```bash
# View logs
docker-compose logs -f [service-name]

# Restart services
docker-compose restart [service-name]

# Update stack
docker-compose pull && docker-compose up -d

# Stop stack
docker-compose down

# Stop and remove data
docker-compose down -v
```

### Health Checks
```bash
# Check service status
docker-compose ps

# Test endpoints
curl -k https://your-domain.com/grafana/api/health
curl -k https://your-domain.com/prometheus/-/healthy
```

## 📊 Monitoring Capabilities

### System Metrics
- CPU, Memory, Disk usage
- Network I/O and connections
- System load and processes
- Temperature and hardware sensors

### Container Metrics
- Container resource usage
- Docker daemon metrics
- Container lifecycle events
- Image and volume statistics

### Application Metrics
- HTTP request metrics
- Database connections
- Cache hit/miss ratios
- Custom application metrics

### Log Aggregation
- System logs (syslog, auth, kernel)
- Application logs with structured logging
- Container logs with metadata
- nginx access and error logs

### Distributed Tracing
- HTTP request tracing
- Database query tracing
- Service dependency mapping
- Performance bottleneck identification

## 🚨 Alerting

### Alert Rules
Configured alerts for:
- System resource exhaustion
- Service downtime
- High error rates
- Performance degradation
- Security events

### Notification Channels
- Email notifications
- Slack integration
- Webhook notifications
- Uptime Kuma integration

## 🔒 Security

### Network Security
- Internal Docker networks
- Service isolation
- Port restrictions
- TLS encryption

### Authentication
- Grafana user authentication
- nginx rate limiting
- Service-to-service authentication
- Secret management

### Data Protection
- Encrypted communications
- Data retention policies
- Backup strategies
- Log sanitization

## 📈 Performance

### Resource Optimization
- Memory limits per service
- CPU allocation
- Disk I/O optimization
- Network bandwidth management

### Data Retention
- Prometheus: 30 days
- Loki: 30 days
- Jaeger: 7 days
- Log rotation: Daily

## 🌐 Domain Configuration Guide

### Step-by-Step Domain Setup

#### 1. Purchase and Configure Domain
```bash
# 1. Purchase domain from registrar (Namecheap, GoDaddy, etc.)
# 2. Point nameservers to your DNS provider (Cloudflare recommended)
# 3. Configure DNS records as shown below
```

#### 2. DNS Records Configuration

**For Cloudflare (Recommended)**:
```
Type    Name                        Content         Proxy   TTL
A       your-domain.com             YOUR_SERVER_IP  ✅      Auto
A       monitoring                  YOUR_SERVER_IP  ✅      Auto
A       status                      YOUR_SERVER_IP  ✅      Auto
A       prometheus                  YOUR_SERVER_IP  ✅      Auto
A       jaeger                      YOUR_SERVER_IP  ✅      Auto
A       loki                        YOUR_SERVER_IP  ✅      Auto
```

**For Other DNS Providers**:
```
your-domain.com                A       YOUR_SERVER_IP
monitoring.your-domain.com     A       YOUR_SERVER_IP
status.your-domain.com         A       YOUR_SERVER_IP
prometheus.your-domain.com     A       YOUR_SERVER_IP
jaeger.your-domain.com         A       YOUR_SERVER_IP
loki.your-domain.com           A       YOUR_SERVER_IP
```

#### 3. Verify DNS Propagation
```bash
# Check DNS propagation (may take 24-48 hours)
nslookup your-domain.com
nslookup monitoring.your-domain.com

# Online tools
# https://www.whatsmydns.net/
# https://dnschecker.org/
```

#### 4. Test Domain Resolution
```bash
# From your server
ping your-domain.com
ping monitoring.your-domain.com

# Test HTTP response
curl -I http://your-domain.com
curl -I http://monitoring.your-domain.com
```

### VPS Provider Specific Notes

#### DigitalOcean
```bash
# Enable firewall
ufw allow ssh
ufw allow 80
ufw allow 443
ufw enable

# Configure domain in DO control panel
# Point A records to your droplet's IP
```

#### AWS EC2
```bash
# Configure Security Groups
# Allow inbound: HTTP (80), HTTPS (443), SSH (22)

# Use Route 53 for DNS (optional)
# Create hosted zone for your domain
```

#### Linode
```bash
# Configure Linode Firewall
# Allow HTTP/HTTPS and SSH

# Use Linode DNS Manager
# Add domain and configure records
```

#### Hetzner
```bash
# Configure Hetzner Cloud Firewall
# Allow ports 22, 80, 443

# Use Hetzner DNS Console
# Add domain and configure A records
```

## 🛠️ Troubleshooting

### Common Issues

1. **Domain not resolving**
   ```bash
   # Check DNS propagation
   nslookup your-domain.com
   dig your-domain.com
   
   # Test from different locations
   # Use online DNS checker tools
   ```

2. **SSL certificate issues**
   ```bash
   # Check certificate status
   openssl s_client -connect your-domain.com:443
   
   # Regenerate self-signed cert
   rm nginx/ssl/*
   ./start.sh
   
   # For Let's Encrypt issues
   certbot renew --dry-run
   ```

3. **Services not starting**
   ```bash
   # Check logs
   docker compose logs [service-name]
   
   # Check system resources
   docker stats
   
   # Restart specific service
   docker compose restart [service-name]
   ```

4. **Can't access services**
   ```bash
   # Check if ports are open
   netstat -tlnp | grep :80
   netstat -tlnp | grep :443
   
   # Check firewall
   ufw status
   
   # Test internal connectivity
   docker compose exec nginx curl http://grafana:3000/api/health
   ```

5. **Permission issues**
   ```bash
   # Fix permissions
   sudo chown -R 1000:1000 grafana/
   sudo chown -R 65534:65534 prometheus/
   
   # Check volume permissions
   docker volume inspect open-observality-final-boss_grafana_data
   ```

6. **High resource usage**
   ```bash
   # Check resource limits
   docker compose config
   
   # Monitor resource usage
   docker stats --no-stream
   
   # Adjust retention policies
   nano prometheus/prometheus.yml
   nano loki/loki.yml
   ```

### Debug Mode
Enable debug logging:
```bash
# Edit .env
LOG_LEVEL=debug
NGINX_LOG_LEVEL=debug

# Restart stack
docker-compose restart
```

## 📚 Documentation

### Service Documentation
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Loki](https://grafana.com/docs/loki/)
- [Jaeger](https://www.jaegertracing.io/docs/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)

### Configuration References
- [Prometheus Configuration](prometheus/prometheus.yml)
- [Grafana Provisioning](grafana/provisioning/)
- [nginx Configuration](nginx/nginx.conf)
- [Alert Rules](prometheus/rules/alerts.yml)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- Create an issue for bug reports
- Join discussions for questions
- Check documentation for configuration help
- Review logs for troubleshooting

## ✅ Quick Setup Checklist

### Before Deployment
- [ ] **Server Setup**: VPS with Docker and Docker Compose installed
- [ ] **Domain Purchased**: Domain name registered and configured
- [ ] **DNS Records**: All A records pointing to your server IP
- [ ] **Firewall**: Ports 22, 80, 443 open
- [ ] **Environment**: `.env` file configured with your domain and passwords

### DNS Records Checklist
- [ ] `your-domain.com` → `YOUR_SERVER_IP`
- [ ] `monitoring.your-domain.com` → `YOUR_SERVER_IP`
- [ ] `status.your-domain.com` → `YOUR_SERVER_IP`
- [ ] `prometheus.your-domain.com` → `YOUR_SERVER_IP`
- [ ] `jaeger.your-domain.com` → `YOUR_SERVER_IP`
- [ ] `loki.your-domain.com` → `YOUR_SERVER_IP`

### Configuration Checklist
- [ ] **Domain**: Set `DOMAIN=your-domain.com` in `.env`
- [ ] **Passwords**: All `change_me` passwords updated
- [ ] **Email**: Alert email configured
- [ ] **SSL**: Production SSL certificates (Let's Encrypt recommended)
- [ ] **Testing**: All services accessible via HTTPS

### Post-Deployment Verification
- [ ] **Services Running**: All containers healthy (`docker compose ps`)
- [ ] **Web Access**: All dashboards accessible via HTTPS
- [ ] **SSL Valid**: No certificate warnings in browser
- [ ] **Monitoring**: Grafana showing metrics
- [ ] **Logging**: Loki receiving logs
- [ ] **Alerting**: Alertmanager configuration tested

### Production Hardening
- [ ] **Passwords**: Strong, unique passwords for all services
- [ ] **Firewall**: Restrictive firewall rules
- [ ] **Updates**: System packages updated
- [ ] **Backups**: Data backup strategy implemented
- [ ] **Monitoring**: Uptime monitoring configured
- [ ] **SSL Renewal**: Automatic certificate renewal set up

---

**⚡ Ready to monitor everything?** Run `./start.sh` and start observing your infrastructure like a pro!

### 🚀 One-Command Setup
```bash
# Complete setup with domain configuration
DOMAIN=your-domain.com ./start.sh
```

### 📞 Need Help?
- 📖 Check the [troubleshooting guide](#troubleshooting)
- 🐛 Report issues on [GitHub](https://github.com/your-repo/issues)
- 💬 Join our [Discord community](https://discord.gg/your-server)
- 📧 Email support: support@your-domain.com