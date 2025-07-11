#!/bin/bash

# Observability Stack Startup Script
# This script helps you deploy the observability stack with service selection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_service() {
    echo -e "${PURPLE}[SERVICE]${NC} $1"
}

print_option() {
    echo -e "${CYAN}$1${NC}"
}

# Service groups and their dependencies
declare -A SERVICE_GROUPS=(
    ["core"]="nginx postgres redis"
    ["monitoring"]="prometheus grafana alertmanager node-exporter cadvisor"
    ["logging"]="loki promtail"
    ["tracing"]="jaeger otel-collector"
    ["health"]="uptime-kuma blackbox-exporter"
    ["utilities"]="logrotate"
)

# Service descriptions
declare -A SERVICE_DESCRIPTIONS=(
    ["nginx"]="Reverse proxy with SSL termination"
    ["postgres"]="PostgreSQL database"
    ["redis"]="Redis cache and session store"
    ["prometheus"]="Metrics collection and storage"
    ["grafana"]="Dashboards and visualization"
    ["alertmanager"]="Alert management and routing"
    ["node-exporter"]="System metrics exporter"
    ["cadvisor"]="Container metrics exporter"
    ["loki"]="Log aggregation system"
    ["promtail"]="Log collection agent"
    ["jaeger"]="Distributed tracing system"
    ["otel-collector"]="OpenTelemetry data collector"
    ["uptime-kuma"]="Uptime monitoring dashboard"
    ["blackbox-exporter"]="Black-box monitoring"
    ["logrotate"]="Log rotation utility"
)

# Service dependencies
declare -A SERVICE_DEPS=(
    ["grafana"]="postgres redis"
    ["alertmanager"]="postgres"
    ["prometheus"]="node-exporter cadvisor"
    ["promtail"]="loki"
    ["otel-collector"]="jaeger prometheus"
)

# Selected services array
SELECTED_SERVICES=()

# Function to display banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🔍 Observability Stack Deployment                           ║"
    echo "║                                                                                ║"
    echo "║  Select the monitoring components you need for your infrastructure             ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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

# Function to show service selection menu
show_service_menu() {
    print_header "Service Selection"
    echo
    print_option "📦 Predefined Stacks:"
    print_option "  1) 🎯 Complete Stack (All services)"
    print_option "  2) 📊 Monitoring Only (Prometheus + Grafana + Core)"
    print_option "  3) 📝 Logging Only (Loki + Promtail + Core)"
    print_option "  4) 🔍 Tracing Only (Jaeger + OpenTelemetry + Core)"
    print_option "  5) 💓 Health Monitoring (Uptime Kuma + Blackbox + Core)"
    print_option "  6) 🔧 Core Infrastructure Only (nginx + PostgreSQL + Redis)"
    print_option "  7) 🎛️  Custom Selection (Choose individual services)"
    echo
    print_option "📋 Quick Stacks:"
    print_option "  8) 🚀 Development (Monitoring + Logging - minimal)"
    print_option "  9) 🏭 Production (Complete stack with health monitoring)"
    print_option " 10) 🔬 Debugging (Tracing + Logging + Monitoring)"
    echo
    
    read -p "Enter your choice (1-10): " choice
    
    case $choice in
        1) select_complete_stack;;
        2) select_monitoring_stack;;
        3) select_logging_stack;;
        4) select_tracing_stack;;
        5) select_health_stack;;
        6) select_core_stack;;
        7) select_custom_services;;
        8) select_development_stack;;
        9) select_production_stack;;
        10) select_debugging_stack;;
        *) print_error "Invalid choice. Please try again."; show_service_menu;;
    esac
}

# Predefined stack selections
select_complete_stack() {
    SELECTED_SERVICES=($(echo "${SERVICE_GROUPS[@]}" | tr ' ' '\n' | sort -u))
    print_status "Selected: Complete observability stack"
}

select_monitoring_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} ${SERVICE_GROUPS["monitoring"]})
    print_status "Selected: Monitoring stack (Prometheus + Grafana + Core)"
}

select_logging_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} ${SERVICE_GROUPS["logging"]} ${SERVICE_GROUPS["utilities"]})
    print_status "Selected: Logging stack (Loki + Promtail + Core)"
}

select_tracing_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} ${SERVICE_GROUPS["tracing"]})
    print_status "Selected: Tracing stack (Jaeger + OpenTelemetry + Core)"
}

select_health_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} ${SERVICE_GROUPS["health"]})
    print_status "Selected: Health monitoring stack"
}

select_core_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]})
    print_status "Selected: Core infrastructure only"
}

select_development_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} prometheus grafana node-exporter loki promtail)
    print_status "Selected: Development stack (lightweight monitoring + logging)"
}

select_production_stack() {
    SELECTED_SERVICES=($(echo "${SERVICE_GROUPS[@]}" | tr ' ' '\n' | sort -u))
    print_status "Selected: Production stack (complete observability)"
}

select_debugging_stack() {
    SELECTED_SERVICES=(${SERVICE_GROUPS["core"]} ${SERVICE_GROUPS["monitoring"]} ${SERVICE_GROUPS["logging"]} ${SERVICE_GROUPS["tracing"]})
    print_status "Selected: Debugging stack (monitoring + logging + tracing)"
}

# Custom service selection
select_custom_services() {
    print_header "Custom Service Selection"
    echo
    print_option "Available services:"
    
    local all_services=($(echo "${SERVICE_GROUPS[@]}" | tr ' ' '\n' | sort -u))
    local i=1
    
    for service in "${all_services[@]}"; do
        printf "%2d) %-20s - %s\n" $i "$service" "${SERVICE_DESCRIPTIONS[$service]}"
        ((i++))
    done
    
    echo
    echo "Enter service numbers separated by spaces (e.g., 1 3 5 7):"
    echo "Or enter service names directly (e.g., nginx prometheus grafana):"
    read -p "Selection: " selection
    
    # Parse selection
    if [[ $selection =~ ^[0-9\ ]+$ ]]; then
        # Numbers provided
        for num in $selection; do
            if [ $num -ge 1 ] && [ $num -le ${#all_services[@]} ]; then
                SELECTED_SERVICES+=(${all_services[$((num-1))]})
            fi
        done
    else
        # Service names provided
        SELECTED_SERVICES=($selection)
    fi
    
    print_status "Selected services: ${SELECTED_SERVICES[*]}"
}

# Function to resolve dependencies
resolve_dependencies() {
    print_header "Resolving service dependencies..."
    
    local resolved_services=()
    local to_process=("${SELECTED_SERVICES[@]}")
    
    while [ ${#to_process[@]} -gt 0 ]; do
        local current=${to_process[0]}
        to_process=("${to_process[@]:1}")
        
        # Skip if already processed
        if [[ " ${resolved_services[@]} " =~ " ${current} " ]]; then
            continue
        fi
        
        # Add current service
        resolved_services+=("$current")
        
        # Add dependencies if they exist
        if [ -n "${SERVICE_DEPS[$current]}" ]; then
            for dep in ${SERVICE_DEPS[$current]}; do
                if [[ ! " ${resolved_services[@]} " =~ " ${dep} " ]]; then
                    to_process+=("$dep")
                    print_status "Adding dependency: $dep (required by $current)"
                fi
            done
        fi
    done
    
    # Always include nginx if any service is selected (needed for reverse proxy)
    if [ ${#resolved_services[@]} -gt 0 ] && [[ ! " ${resolved_services[@]} " =~ " nginx " ]]; then
        resolved_services=("nginx" "${resolved_services[@]}")
        print_status "Adding nginx (required for reverse proxy)"
    fi
    
    SELECTED_SERVICES=("${resolved_services[@]}")
    print_status "Final service list: ${SELECTED_SERVICES[*]}"
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
    if [ -f "nginx/nginx.conf" ]; then
        sed -i.bak "s/your-domain.com/${DOMAIN}/g" nginx/nginx.conf
    fi
    
    # Update other configs only if services are selected
    if [[ " ${SELECTED_SERVICES[@]} " =~ " prometheus " ]]; then
        sed -i.bak "s/your-domain.com/${DOMAIN}/g" prometheus/prometheus.yml
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " blackbox-exporter " ]]; then
        sed -i.bak "s/your-domain.com/${DOMAIN}/g" blackbox/blackbox.yml
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " alertmanager " ]]; then
        sed -i.bak "s/your-domain.com/${DOMAIN}/g" alertmanager/alertmanager.yml
    fi
    
    print_status "Configuration files updated with domain: ${DOMAIN}"
}

# Start the selected services
start_stack() {
    print_header "Starting selected services..."
    
    # Create services list for docker-compose
    local services_arg=""
    for service in "${SELECTED_SERVICES[@]}"; do
        services_arg="$services_arg $service"
    done
    
    # Pull images for selected services
    print_status "Pulling Docker images for selected services..."
    docker-compose pull $services_arg
    
    # Start the selected services
    print_status "Starting services: ${SELECTED_SERVICES[*]}"
    docker-compose up -d $services_arg
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Check service health
    print_status "Checking service health..."
    docker-compose ps $services_arg
}

# Display access information for selected services
show_access_info() {
    print_header "Observability Stack Access Information"
    
    DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    
    echo
    echo "🌐 Available Web Interfaces:"
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " grafana " ]]; then
        echo "  - 📊 Grafana (Main Dashboard): https://${DOMAIN}/grafana/"
        echo "    └── Credentials: admin / $(grep "GRAFANA_ADMIN_PASSWORD=" .env | cut -d'=' -f2)"
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " prometheus " ]]; then
        echo "  - 📈 Prometheus: https://${DOMAIN}/prometheus/"
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " jaeger " ]]; then
        echo "  - 🔍 Jaeger (Tracing): https://${DOMAIN}/jaeger/"
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " uptime-kuma " ]]; then
        echo "  - 💓 Uptime Kuma (Status): https://${DOMAIN}/uptime/"
        echo "    └── Set up on first visit"
    fi
    
    if [[ " ${SELECTED_SERVICES[@]} " =~ " alertmanager " ]]; then
        echo "  - 🚨 Alertmanager: https://${DOMAIN}/alertmanager/"
    fi
    
    echo
    echo "📊 Alternative Subdomains (if DNS configured):"
    if [[ " ${SELECTED_SERVICES[@]} " =~ " grafana " ]]; then
        echo "  - Monitoring: https://monitoring.${DOMAIN}/"
    fi
    if [[ " ${SELECTED_SERVICES[@]} " =~ " uptime-kuma " ]]; then
        echo "  - Status Page: https://status.${DOMAIN}/"
    fi
    
    echo
    echo "🔧 Service Management:"
    echo "  - View logs: docker-compose logs -f [service-name]"
    echo "  - Stop stack: docker-compose down"
    echo "  - Restart service: docker-compose restart [service-name]"
    echo "  - Update stack: docker-compose pull && docker-compose up -d"
    echo
    echo "📋 Running Services:"
    for service in "${SELECTED_SERVICES[@]}"; do
        echo "  ✓ $service - ${SERVICE_DESCRIPTIONS[$service]}"
    done
    echo
}

# Show deployment summary
show_deployment_summary() {
    print_header "Deployment Summary"
    echo
    print_service "Services deployed: ${#SELECTED_SERVICES[@]}"
    print_service "Total containers: $(docker-compose ps -q | wc -l)"
    print_service "Stack status: $(docker-compose ps --services --filter status=running | wc -l)/${#SELECTED_SERVICES[@]} running"
    echo
}

# Handle command line arguments
handle_arguments() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --complete)
            select_complete_stack
            ;;
        --monitoring)
            select_monitoring_stack
            ;;
        --logging)
            select_logging_stack
            ;;
        --tracing)
            select_tracing_stack
            ;;
        --health)
            select_health_stack
            ;;
        --core)
            select_core_stack
            ;;
        --dev)
            select_development_stack
            ;;
        --prod)
            select_production_stack
            ;;
        --debug)
            select_debugging_stack
            ;;
        --services=*)
            local services="${1#*=}"
            SELECTED_SERVICES=(${services//,/ })
            print_status "Selected services from command line: ${SELECTED_SERVICES[*]}"
            ;;
        "")
            # No arguments, show interactive menu
            return 1
            ;;
        *)
            print_error "Unknown argument: $1"
            show_help
            exit 1
            ;;
    esac
    return 0
}

# Show help message
show_help() {
    echo "Observability Stack Deployment Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --complete    Deploy complete observability stack"
    echo "  --monitoring  Deploy monitoring stack (Prometheus + Grafana)"
    echo "  --logging     Deploy logging stack (Loki + Promtail)"
    echo "  --tracing     Deploy tracing stack (Jaeger + OpenTelemetry)"
    echo "  --health      Deploy health monitoring stack"
    echo "  --core        Deploy core infrastructure only"
    echo "  --dev         Deploy development stack (lightweight)"
    echo "  --prod        Deploy production stack (complete)"
    echo "  --debug       Deploy debugging stack (monitoring + logging + tracing)"
    echo "  --services=   Deploy specific services (comma-separated)"
    echo "  --help, -h    Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Interactive menu"
    echo "  $0 --monitoring                       # Deploy monitoring stack"
    echo "  $0 --services=nginx,prometheus,grafana # Deploy specific services"
    echo
}

# Main execution
main() {
    show_banner
    
    # Handle command line arguments
    if handle_arguments "$@"; then
        # Arguments processed, skip interactive menu
        :
    else
        # No arguments or interactive mode
        show_service_menu
    fi
    
    echo
    print_header "Starting deployment with selected services..."
    echo
    
    check_prerequisites
    check_env_file
    resolve_dependencies
    create_directories
    generate_ssl_cert
    update_configs
    start_stack
    show_deployment_summary
    show_access_info
    
    print_status "✅ Observability stack deployment completed successfully!"
    print_status "Your monitoring infrastructure is ready to use."
}

# Run main function with all arguments
main "$@"