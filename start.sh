#!/bin/bash

# Observability Stack Startup Script
# This script helps you deploy the complete observability stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Check if Docker and Docker Compose are installed
check_prerequisites() {
    print_header "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Docker and Docker Compose are available"
}

# Check if .env file exists and is configured
check_env_file() {
    print_header "Checking environment configuration..."
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found. Please copy .env.example to .env and configure it."
        exit 1
    fi
    
    # Check if default passwords are still in use
    if grep -q "change_me" .env; then
        print_warning "Default passwords detected in .env file. Please update them for security."
        echo "Found default passwords for:"
        grep "change_me" .env | cut -d'=' -f1 | sed 's/^/  - /'
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Please update the passwords in .env file and run again."
            exit 1
        fi
    fi
    
    print_status "Environment configuration checked"
}

# Create necessary directories
create_directories() {
    print_header "Creating necessary directories..."
    
    # Create SSL directory for nginx
    mkdir -p nginx/ssl
    
    # Create log directories
    mkdir -p nginx/logs
    mkdir -p logs/{grafana,prometheus,loki,jaeger}
    
    # Set proper permissions
    chmod 755 nginx/logs
    chmod -R 755 logs/
    
    print_status "Directories created"
}

# Generate self-signed SSL certificate (for development)
generate_ssl_cert() {
    print_header "Checking SSL certificates..."
    
    if [ ! -f "nginx/ssl/cert.pem" ] || [ ! -f "nginx/ssl/key.pem" ]; then
        print_warning "SSL certificates not found. Generating self-signed certificate..."
        
        # Load domain from .env
        DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/key.pem \
            -out nginx/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}"
        
        print_status "Self-signed SSL certificate generated"
        print_warning "For production, replace with proper SSL certificates"
    else
        print_status "SSL certificates found"
    fi
}

# Update configuration files with domain
update_configs() {
    print_header "Updating configuration files..."
    
    # Load domain from .env
    DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    
    # Update nginx configuration
    sed -i.bak "s/your-domain.com/${DOMAIN}/g" nginx/nginx.conf
    sed -i.bak "s/your-domain.com/${DOMAIN}/g" prometheus/prometheus.yml
    sed -i.bak "s/your-domain.com/${DOMAIN}/g" blackbox/blackbox.yml
    sed -i.bak "s/your-domain.com/${DOMAIN}/g" alertmanager/alertmanager.yml
    
    print_status "Configuration files updated with domain: ${DOMAIN}"
}

# Start the stack
start_stack() {
    print_header "Starting observability stack..."
    
    # Pull latest images
    print_status "Pulling Docker images..."
    docker-compose pull
    
    # Start the stack
    print_status "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    print_status "Checking service health..."
    docker-compose ps
}

# Display access information
show_access_info() {
    print_header "Observability Stack Access Information"
    
    DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    
    echo
    echo "🌐 Web Interfaces:"
    echo "  - Grafana (Main Dashboard): https://${DOMAIN}/grafana/"
    echo "  - Prometheus: https://${DOMAIN}/prometheus/"
    echo "  - Jaeger (Tracing): https://${DOMAIN}/jaeger/"
    echo "  - Uptime Kuma (Status): https://${DOMAIN}/uptime/"
    echo "  - Alertmanager: https://${DOMAIN}/alertmanager/"
    echo
    echo "📊 Alternative Subdomains:"
    echo "  - Monitoring: https://monitoring.${DOMAIN}/"
    echo "  - Status Page: https://status.${DOMAIN}/"
    echo
    echo "🔐 Default Credentials:"
    echo "  - Grafana: admin / $(grep "GRAFANA_ADMIN_PASSWORD=" .env | cut -d'=' -f2)"
    echo "  - Uptime Kuma: Set up on first visit"
    echo
    echo "📝 Important Notes:"
    echo "  - Update .env file with proper passwords and configurations"
    echo "  - Replace self-signed SSL certificates with proper ones for production"
    echo "  - Configure DNS to point to your server IP"
    echo "  - Set up proper firewall rules"
    echo
    echo "🚀 Quick Commands:"
    echo "  - View logs: docker-compose logs -f [service-name]"
    echo "  - Stop stack: docker-compose down"
    echo "  - Restart stack: docker-compose restart"
    echo "  - Update stack: docker-compose pull && docker-compose up -d"
    echo
}

# Main execution
main() {
    print_header "🔍 Observability Stack Deployment"
    echo
    
    check_prerequisites
    check_env_file
    create_directories
    generate_ssl_cert
    update_configs
    start_stack
    show_access_info
    
    print_status "✅ Observability stack deployment completed successfully!"
    print_status "Check the access information above to start using your monitoring stack."
}

# Run main function
main "$@"