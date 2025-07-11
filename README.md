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
- **🎛️ Modular**: Choose exactly which services you need

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

### 2. Environment Configuration
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

### 3. Service Selection & Deployment

The start script now offers multiple deployment options:

#### Interactive Mode (Recommended for First-Time Users)
```bash
./start.sh
```

This will present you with an interactive menu to select services:

```
📦 Predefined Stacks:
  1) 🎯 Complete Stack (All services)
  2) 📊 Monitoring Only (Prometheus + Grafana + Core)
  3) 📝 Logging Only (Loki + Promtail + Core)
  4) 🔍 Tracing Only (Jaeger + OpenTelemetry + Core)
  5) 💓 Health Monitoring (Uptime Kuma + Blackbox + Core)
  6) 🔧 Core Infrastructure Only (nginx + PostgreSQL + Redis)
  7) 🎛️ Custom Selection (Choose individual services)

📋 Quick Stacks:
  8) 🚀 Development (Monitoring + Logging - minimal)
  9) 🏭 Production (Complete stack with health monitoring)
 10) 🔬 Debugging (Tracing + Logging + Monitoring)
```

#### Command Line Options (For Automation)
```bash
# Deploy complete stack
./start.sh --complete

# Deploy monitoring stack only
./start.sh --monitoring

# Deploy logging stack only
./start.sh --logging

# Deploy tracing stack only
./start.sh --tracing

# Deploy health monitoring
./start.sh --health

# Deploy core infrastructure only
./start.sh --core

# Deploy development stack (lightweight)
./start.sh --dev

# Deploy production stack (complete)
./start.sh --prod

# Deploy debugging stack
./start.sh --debug

# Deploy specific services
./start.sh --services=nginx,prometheus,grafana,postgres

# Show help
./start.sh --help
```

#### Service Selection Examples

**For Small Projects/Development:**
```bash
./start.sh --dev
# Deploys: nginx, postgres, redis, prometheus, grafana, node-exporter, loki, promtail
```

**For Production Monitoring:**
```bash
./start.sh --monitoring
# Deploys: nginx, postgres, redis, prometheus, grafana, alertmanager, node-exporter, cadvisor
```

**For Application Debugging:**
```bash
./start.sh --debug
# Deploys: Complete monitoring + logging + tracing stack
```

**Custom Selection:**
```bash
./start.sh --services=nginx,prometheus,grafana
# Deploys: Only specified services (dependencies auto-resolved)
```

### 4. Available Services

| Service | Description | Dependencies |
|---------|-------------|--------------|
| **nginx** | Reverse proxy with SSL termination | None |
| **postgres** | PostgreSQL database | None |
| **redis** | Redis cache and session store | None |
| **prometheus** | Metrics collection and storage | node-exporter, cadvisor |
| **grafana** | Dashboards and visualization | postgres, redis |
| **alertmanager** | Alert management and routing | postgres |
| **node-exporter** | System metrics exporter | None |
| **cadvisor** | Container metrics exporter | None |
| **loki** | Log aggregation system | None |
| **promtail** | Log collection agent | loki |
| **jaeger** | Distributed tracing system | None |
| **otel-collector** | OpenTelemetry data collector | jaeger, prometheus |
| **uptime-kuma** | Uptime monitoring dashboard | None |
| **blackbox-exporter** | Black-box monitoring | None |
| **logrotate** | Log rotation utility | None |

### 5. Access Services

The available services depend on your selection. Common access points:

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

## 📦 Service Groups & Stack Templates

### 🎯 Complete Stack
**All services** - Full observability with monitoring, logging, tracing, and health checks
```bash
./start.sh --complete
```
- ✅ System monitoring (Prometheus + Grafana)
- ✅ Log aggregation (Loki + Promtail)
- ✅ Distributed tracing (Jaeger + OpenTelemetry)
- ✅ Health monitoring (Uptime Kuma + Blackbox)
- ✅ Alert management (Alertmanager)

### 📊 Monitoring Stack
**Core monitoring** - Essential metrics and dashboards
```bash
./start.sh --monitoring
```
- ✅ Prometheus metrics collection
- ✅ Grafana dashboards
- ✅ System & container monitoring
- ✅ Alert management

### 📝 Logging Stack
**Log management** - Centralized logging solution
```bash
./start.sh --logging
```
- ✅ Loki log aggregation
- ✅ Promtail log collection
- ✅ Log rotation management
- ✅ Core infrastructure

### 🔍 Tracing Stack
**Distributed tracing** - Application performance monitoring
```bash
./start.sh --tracing
```
- ✅ Jaeger tracing UI
- ✅ OpenTelemetry collector
- ✅ Request flow visualization
- ✅ Performance analysis

### 💓 Health Monitoring Stack
**Uptime & availability** - Service health tracking
```bash
./start.sh --health
```
- ✅ Uptime Kuma dashboard
- ✅ Blackbox monitoring
- ✅ Service availability tracking
- ✅ Status page

### 🚀 Development Stack
**Lightweight monitoring** - Perfect for development environments
```bash
./start.sh --dev
```
- ✅ Basic monitoring (Prometheus + Grafana)
- ✅ Log collection (Loki + Promtail)
- ✅ Minimal resource usage
- ✅ Quick setup

### 🔬 Debugging Stack
**Comprehensive debugging** - When you need to troubleshoot
```bash
./start.sh --debug
```
- ✅ Full monitoring capabilities
- ✅ Complete log aggregation
- ✅ Distributed tracing
- ✅ Performance analysis tools

## 📋 Configuration

### Environment Variables
Key variables in `.env`:
- `DOMAIN`: Your domain name
- `GRAFANA_ADMIN_PASSWORD`: Grafana admin password
- `POSTGRES_PASSWORD`: Database password
- `REDIS_PASSWORD`: Redis password
- `ALERT_EMAIL`: Email for alerts
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications

### Example .env Configuration
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

#### SSL Certificate Renewal
```bash
# Add to crontab for automatic renewal
0 3 * * * certbot renew --quiet && docker compose restart nginx
```

## 🔧 Management

### Common Commands
```bash
# View logs for specific service
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]

# Update and restart stack
docker-compose pull && docker-compose up -d

# Stop all services
docker-compose down

# Stop and remove data
docker-compose down -v

# Check service status
docker-compose ps

# View resource usage
docker stats
```

### Service-Specific Management

#### Start Additional Services
```bash
# Add monitoring to existing logging stack
docker-compose up -d prometheus grafana node-exporter

# Add tracing to existing stack
docker-compose up -d jaeger otel-collector
```

#### Remove Services
```bash
# Stop specific services
docker-compose stop uptime-kuma blackbox-exporter

# Remove stopped services
docker-compose rm uptime-kuma blackbox-exporter
```

### Health Checks
```bash
# Check service status
docker-compose ps

# Test specific endpoints
curl -k https://your-domain.com/grafana/api/health
curl -k https://your-domain.com/prometheus/-/healthy

# View service logs
docker-compose logs --tail=50 grafana
docker-compose logs --tail=50 prometheus
```

## 🌐 Domain Configuration Guide

### Step-by-Step Domain Setup

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

## 🛠️ Troubleshooting

### Common Issues

1. **Services won't start**
   ```bash
   # Check dependencies
   ./start.sh --services=nginx,postgres,redis
   
   # Then add other services
   docker-compose up -d prometheus grafana
   ```

2. **Domain not resolving**
   ```bash
   # Check DNS propagation
   nslookup your-domain.com
   dig your-domain.com
   ```

3. **SSL certificate issues**
   ```bash
   # Regenerate self-signed cert
   rm nginx/ssl/*
   ./start.sh --core
   ```

4. **Resource constraints**
   ```bash
   # Use lightweight stack
   ./start.sh --dev
   
   # Or minimal monitoring
   ./start.sh --services=nginx,prometheus,grafana
   ```

5. **Service-specific issues**
   ```bash
   # Check individual service logs
   docker-compose logs [service-name]
   
   # Restart problematic service
   docker-compose restart [service-name]
   ```

### Debug Mode
Enable detailed logging:
```bash
# Check service selection
./start.sh --help

# Test with core services only
./start.sh --core

# Add services incrementally
docker-compose up -d prometheus
docker-compose up -d grafana
```

## 📚 Deployment Examples

### Small Team Development
```bash
# Minimal monitoring for development
./start.sh --dev

# Equivalent to:
./start.sh --services=nginx,postgres,redis,prometheus,grafana,node-exporter,loki,promtail
```

### Production Microservices
```bash
# Full observability for production
./start.sh --prod

# Or step by step:
./start.sh --monitoring    # Start with monitoring
docker-compose up -d loki promtail  # Add logging
docker-compose up -d jaeger otel-collector  # Add tracing
```

### Debugging Performance Issues
```bash
# Complete debugging stack
./start.sh --debug

# Focus on specific areas:
./start.sh --tracing      # For application performance
./start.sh --logging      # For log analysis
./start.sh --monitoring   # For resource monitoring
```

### Infrastructure Monitoring Only
```bash
# Just system monitoring
./start.sh --monitoring

# Add health checks
docker-compose up -d uptime-kuma blackbox-exporter
```

## ✅ Quick Setup Checklist

### Before Deployment
- [ ] **Server Setup**: VPS with Docker and Docker Compose installed
- [ ] **Domain Purchased**: Domain name registered and configured
- [ ] **DNS Records**: All A records pointing to your server IP
- [ ] **Firewall**: Ports 22, 80, 443 open
- [ ] **Environment**: `.env` file configured with your domain and passwords

### Service Selection Checklist
- [ ] **Requirements**: Identified monitoring needs (metrics, logs, traces, health)
- [ ] **Resources**: Estimated server capacity for selected services
- [ ] **Dependencies**: Understood service relationships and requirements
- [ ] **Access**: Planned which dashboards and interfaces you need

### Deployment Options
- [ ] **Interactive**: Use `./start.sh` for guided selection
- [ ] **Automated**: Use `./start.sh --[option]` for scripted deployment
- [ ] **Custom**: Use `./start.sh --services=...` for specific services
- [ ] **Incremental**: Start with core, add services as needed

### Post-Deployment Verification
- [ ] **Services Running**: All selected containers healthy (`docker compose ps`)
- [ ] **Web Access**: All selected dashboards accessible via HTTPS
- [ ] **SSL Valid**: No certificate warnings in browser
- [ ] **Data Flow**: Metrics, logs, and traces flowing properly
- [ ] **Alerts**: Alerting system configured and tested

### Production Hardening
- [ ] **Passwords**: Strong, unique passwords for all services
- [ ] **Firewall**: Restrictive firewall rules
- [ ] **Updates**: System packages updated
- [ ] **Backups**: Data backup strategy implemented
- [ ] **Monitoring**: Uptime monitoring configured
- [ ] **SSL Renewal**: Automatic certificate renewal set up

---

## 🚀 Quick Start Commands

### One-Line Deployments
```bash
# Complete observability stack
./start.sh --complete

# Development environment
./start.sh --dev

# Production monitoring
./start.sh --prod

# Custom selection
./start.sh --services=nginx,prometheus,grafana,loki
```

### Interactive Setup
```bash
# Guided deployment with menu
./start.sh
```

### Get Help
```bash
# Show all options
./start.sh --help

# Check service status
docker-compose ps

# View service logs
docker-compose logs -f [service-name]
```

**⚡ Ready to monitor everything?** Choose your deployment option and start observing your infrastructure like a pro!

### 📞 Need Help?
- 📖 Check the [troubleshooting guide](#troubleshooting)
- 🐛 Report issues on [GitHub](https://github.com/your-repo/issues)
- 💬 Join our [Discord community](https://discord.gg/your-server)
- 📧 Email support: support@your-domain.com