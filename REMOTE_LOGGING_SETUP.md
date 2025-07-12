# Remote Application Logging Setup

This guide shows how to stream logs from any remote application/system to your centralized Loki instance for monitoring and analysis.

## Prerequisites

- Remote server/VPS with your application running
- Docker installed (for containerized applications)
- Access to your centralized Loki instance (e.g., `monitoring.your-domain.com:3100`)
- Basic knowledge of your application's logging mechanism

## Option 1: Add Promtail Container (Recommended)

This approach works with any application and captures both file-based logs and container logs.

### 1. Create Promtail Configuration

On your application server, create `promtail/promtail.yml`:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://your-loki-server:3100/loki/api/v1/push

scrape_configs:
  # File-based logs
  - job_name: app-files
    static_configs:
      - targets:
          - localhost
        labels:
          job: your-app-name
          server: your-server-name
          environment: production  # or staging, dev, etc.
          __path__: /var/log/app/*.log
          
  # Container logs (for Docker applications)
  - job_name: app-containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: 'container_name'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: 'service'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_project']
        target_label: 'project'
        
  # System logs (optional)
  - job_name: system-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          server: your-server-name
          __path__: /var/log/syslog
          
  # Nginx/Apache logs (optional)
  - job_name: web-server
    static_configs:
      - targets:
          - localhost
        labels:
          job: webserver
          server: your-server-name
          __path__: /var/log/nginx/*.log
```

### 2. Add Promtail to Docker Compose

Add this to your application's `docker-compose.yml`:

```yaml
services:
  # ... your existing application services ...
  
  promtail:
    image: grafana/promtail:2.9.0
    container_name: promtail
    volumes:
      - ./promtail/promtail.yml:/etc/promtail/promtail.yml
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      # Add any additional log directories your app uses
      - ./app-logs:/var/log/app:ro
    command: -config.file=/etc/promtail/promtail.yml
    restart: unless-stopped
    networks:
      - your-app-network  # Use your app's network
```

### 3. Configure Application Logging

Choose the appropriate configuration for your application type:

#### For Python Applications (Django, Flask, FastAPI, etc.)
```python
import logging
import os

# Configure logging to write to files
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'json': {
            'format': '{"level": "%(levelname)s", "time": "%(asctime)s", "module": "%(module)s", "message": "%(message)s", "server": "' + os.getenv('SERVER_NAME', 'unknown') + '"}',
        },
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/app/application.log',
            'formatter': 'json',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'your_app_name': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

#### For Node.js Applications
```javascript
const winston = require('winston');
const path = require('path');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { 
    service: 'your-app-name',
    server: process.env.SERVER_NAME || 'unknown'
  },
  transports: [
    new winston.transports.File({ 
      filename: '/var/log/app/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: '/var/log/app/application.log' 
    }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

module.exports = logger;
```

#### For Java Applications (Spring Boot, etc.)
```xml
<!-- logback-spring.xml -->
<configuration>
    <appender name="FILE" class="ch.qos.logback.core.FileAppender">
        <file>/var/log/app/application.log</file>
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp/>
                <logLevel/>
                <loggerName/>
                <message/>
                <mdc/>
                <pattern>
                    <pattern>{"server": "${SERVER_NAME:-unknown}"}</pattern>
                </pattern>
            </providers>
        </encoder>
    </appender>
    
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="FILE"/>
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

#### For .NET Applications
```csharp
// Program.cs or Startup.cs
using Serilog;
using Serilog.Events;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Server", Environment.GetEnvironmentVariable("SERVER_NAME") ?? "unknown")
    .WriteTo.Console()
    .WriteTo.File("/var/log/app/application.log",
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .CreateLogger();
```

### 4. Update Application Dockerfile

Add log directory creation to your application's Dockerfile:

```dockerfile
# Create log directory
RUN mkdir -p /var/log/app
RUN chmod 755 /var/log/app

# Your existing application setup...

# Set environment variable for server identification
ENV SERVER_NAME=your-server-name
```

### 5. Update Docker Compose Volumes

Update your application service in `docker-compose.yml`:

```yaml
services:
  your-app:
    # ... your existing config ...
    volumes:
      - ./app-logs:/var/log/app
      - # ... your other volumes ...
    environment:
      - SERVER_NAME=your-server-name
```

## Option 2: Direct HTTP Push (Application-Specific)

For applications that can directly push logs to Loki:

### Python Applications
```bash
pip install python-logging-loki
```

```python
import logging_loki

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'loki': {
            'level': 'INFO',
            'class': 'logging_loki.LokiHandler',
            'url': 'http://your-loki-server:3100/loki/api/v1/push',
            'tags': {
                'service': 'your-app-name',
                'server': 'your-server-name',
                'environment': 'production',
            },
            'version': '1',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'your_app': {
            'handlers': ['loki', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

### Node.js Applications
```bash
npm install winston-loki
```

```javascript
const winston = require('winston');
const LokiTransport = require('winston-loki');

const logger = winston.createLogger({
  transports: [
    new LokiTransport({
      host: 'http://your-loki-server:3100',
      labels: {
        service: 'your-app-name',
        server: process.env.SERVER_NAME || 'unknown',
        environment: process.env.NODE_ENV || 'production'
      }
    }),
    new winston.transports.Console()
  ]
});
```

## Option 3: System-Level Logging (Non-Docker)

For applications not running in Docker:

### Install Promtail as System Service

```bash
# Download Promtail
curl -O -L "https://github.com/grafana/loki/releases/download/v2.9.0/promtail-linux-amd64.zip"
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail

# Create config directory
sudo mkdir -p /etc/promtail

# Create systemd service
sudo tee /etc/systemd/system/promtail.service > /dev/null <<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail.yml
Restart=on-failure
RestartSec=20
StandardOutput=journal
StandardError=journal
SyslogIdentifier=promtail

[Install]
WantedBy=multi-user.target
EOF

# Create promtail user
sudo useradd --system promtail

# Start service
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
```

## Starting the Setup

### For Option 1 (Promtail Container):
```bash
# On your application server
docker-compose up -d promtail
```

### For Option 2 (Direct Push):
```bash
# Install appropriate library and restart your application
# Examples shown above for each language
```

### For Option 3 (System Service):
```bash
# Configure and start Promtail service
sudo systemctl start promtail
sudo systemctl status promtail
```

## Security Considerations

### Option A: Expose Loki with Authentication
Add basic auth to your Loki reverse proxy:

```nginx
location /loki/ {
    auth_basic "Loki Push";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://loki:3100/;
}
```

### Option B: Use VPN/Tailscale
Set up a VPN between your servers and use internal IPs.

### Option C: Use HTTPS with Client Certificates
Set up mutual TLS authentication.

### Option D: Network-Level Security
Use firewall rules to restrict access to Loki port:
```bash
# Allow only specific IPs
sudo ufw allow from YOUR_APP_SERVER_IP to any port 3100
```

## Viewing Logs in Grafana

Once set up, you can query logs in Grafana using LogQL:

```logql
# All logs from your application
{job="your-app-name"}

# Logs from specific service
{service="your-app-name"}

# Container logs
{container_name=~".*your-app.*"}

# Error logs only
{job="your-app-name"} |= "ERROR"

# Logs from specific server
{server="your-server-name"}

# Logs from specific environment
{environment="production"}
```

## Troubleshooting

1. **Check Promtail logs**: 
   - Container: `docker logs promtail`
   - System service: `sudo journalctl -u promtail -f`

2. **Check application logs**: 
   - Container: `docker logs your-app-container`
   - System: Check your application's log files

3. **Test Loki connection**: 
   ```bash
   curl http://your-loki-server:3100/ready
   ```

4. **Check firewall**: Ensure Loki port is accessible from your application server

5. **Verify log file permissions**: Ensure Promtail can read your log files

6. **Check disk space**: Ensure sufficient disk space for log files

## Example LogQL Queries

### Basic Queries
- All application logs: `{job="your-app-name"}`
- Error logs only: `{job="your-app-name"} |= "ERROR"`
- Warning and error logs: `{job="your-app-name"} |~ "ERROR|WARN"`
- Last 1 hour: `{job="your-app-name"}[1h]`

### Advanced Queries
- Filter by container: `{container_name="your-app-container"}`
- Filter by server: `{server="your-server-name"}`
- Filter by environment: `{environment="production"}`
- Specific log level: `{job="your-app-name"} | json | level="ERROR"`
- Rate of errors: `rate({job="your-app-name"} |= "ERROR"[5m])`

## Application-Specific Examples

### For Different Frameworks
- **Django**: Use the Python configuration above
- **Flask**: Use the Python configuration above
- **FastAPI**: Use the Python configuration above
- **Express.js**: Use the Node.js configuration above
- **Spring Boot**: Use the Java configuration above
- **ASP.NET Core**: Use the .NET configuration above
- **Go applications**: Use structured logging with logrus or zap
- **Ruby on Rails**: Configure Rails logger to write JSON to files

### For Different Deployment Methods
- **Docker Compose**: Use Option 1 (Promtail Container)
- **Kubernetes**: Use Promtail DaemonSet
- **Systemd services**: Use Option 3 (System Service)
- **PM2 (Node.js)**: Use Option 2 (Direct Push) or configure PM2 logs
- **Nginx/Apache**: Add web server log scraping to Promtail config

This generalized setup can be adapted for virtually any application or system that generates logs.