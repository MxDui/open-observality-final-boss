#!/bin/bash

# Observability Stack Management Script
# This script helps you manage your deployed observability services

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

# Function to display banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🔧 Observability Stack Management                           ║"
    echo "║                                                                                ║"
    echo "║  Manage your deployed monitoring and observability services                    ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get running services
get_running_services() {
    docker-compose ps --services --filter status=running
}

# Get all defined services
get_all_services() {
    docker-compose config --services
}

# Show current status
show_status() {
    print_header "Current Stack Status"
    echo
    
    local running_services=($(get_running_services))
    local all_services=($(get_all_services))
    
    echo "📊 Service Status:"
    echo "  Running: ${#running_services[@]}/${#all_services[@]} services"
    echo
    
    for service in "${all_services[@]}"; do
        if [[ " ${running_services[@]} " =~ " ${service} " ]]; then
            echo "  ✅ $service - Running"
        else
            echo "  ❌ $service - Stopped"
        fi
    done
    echo
    
    # Show resource usage
    print_header "Resource Usage"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null | head -10
    echo
}

# Show management menu
show_menu() {
    print_header "Management Options"
    echo
    print_option "📊 Status & Information:"
    print_option "  1) Show current status"
    print_option "  2) View service logs"
    print_option "  3) Show resource usage"
    print_option "  4) Display access URLs"
    echo
    print_option "🔧 Service Management:"
    print_option "  5) Start additional services"
    print_option "  6) Stop services"
    print_option "  7) Restart services"
    print_option "  8) Update services"
    echo
    print_option "🛠️ Maintenance:"
    print_option "  9) Clean up unused containers/images"
    print_option " 10) Backup configuration"
    print_option " 11) View disk usage"
    print_option " 12) Check service health"
    echo
    print_option " 0) Exit"
    echo
    
    read -p "Enter your choice (0-12): " choice
    
    case $choice in
        1) show_status;;
        2) view_logs;;
        3) show_resources;;
        4) show_access_urls;;
        5) start_services;;
        6) stop_services;;
        7) restart_services;;
        8) update_services;;
        9) cleanup_system;;
        10) backup_config;;
        11) show_disk_usage;;
        12) check_health;;
        0) exit 0;;
        *) print_error "Invalid choice. Please try again."; show_menu;;
    esac
}

# View logs for specific service
view_logs() {
    print_header "Service Logs"
    echo
    
    local running_services=($(get_running_services))
    
    if [ ${#running_services[@]} -eq 0 ]; then
        print_error "No services are currently running."
        return
    fi
    
    echo "Select a service to view logs:"
    local i=1
    for service in "${running_services[@]}"; do
        echo "  $i) $service"
        ((i++))
    done
    echo "  0) Back to menu"
    echo
    
    read -p "Enter your choice: " choice
    
    if [ "$choice" -eq 0 ]; then
        return
    elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#running_services[@]} ]; then
        local selected_service=${running_services[$((choice-1))]}
        print_status "Viewing logs for $selected_service (Press Ctrl+C to exit)"
        docker-compose logs -f "$selected_service"
    else
        print_error "Invalid choice."
    fi
}

# Show resource usage
show_resources() {
    print_header "Resource Usage Details"
    echo
    
    print_service "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo
    
    print_service "System Resources:"
    echo "CPU Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    echo
}

# Show access URLs
show_access_urls() {
    print_header "Service Access URLs"
    echo
    
    if [ -f ".env" ]; then
        DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
    else
        DOMAIN="your-domain.com"
    fi
    
    local running_services=($(get_running_services))
    
    echo "🌐 Available Web Interfaces:"
    
    if [[ " ${running_services[@]} " =~ " grafana " ]]; then
        echo "  📊 Grafana: https://${DOMAIN}/grafana/"
    fi
    
    if [[ " ${running_services[@]} " =~ " prometheus " ]]; then
        echo "  📈 Prometheus: https://${DOMAIN}/prometheus/"
    fi
    
    if [[ " ${running_services[@]} " =~ " jaeger " ]]; then
        echo "  🔍 Jaeger: https://${DOMAIN}/jaeger/"
    fi
    
    if [[ " ${running_services[@]} " =~ " uptime-kuma " ]]; then
        echo "  💓 Uptime Kuma: https://${DOMAIN}/uptime/"
    fi
    
    if [[ " ${running_services[@]} " =~ " alertmanager " ]]; then
        echo "  🚨 Alertmanager: https://${DOMAIN}/alertmanager/"
    fi
    
    echo
}

# Start additional services
start_services() {
    print_header "Start Additional Services"
    echo
    
    local all_services=($(get_all_services))
    local running_services=($(get_running_services))
    local stopped_services=()
    
    # Find stopped services
    for service in "${all_services[@]}"; do
        if [[ ! " ${running_services[@]} " =~ " ${service} " ]]; then
            stopped_services+=("$service")
        fi
    done
    
    if [ ${#stopped_services[@]} -eq 0 ]; then
        print_status "All services are already running."
        return
    fi
    
    echo "Select services to start (space-separated numbers or 'all'):"
    local i=1
    for service in "${stopped_services[@]}"; do
        echo "  $i) $service"
        ((i++))
    done
    echo
    
    read -p "Enter your choice: " selection
    
    if [ "$selection" = "all" ]; then
        print_status "Starting all stopped services..."
        docker-compose up -d "${stopped_services[@]}"
    else
        local services_to_start=()
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#stopped_services[@]} ]; then
                services_to_start+=(${stopped_services[$((num-1))]})
            fi
        done
        
        if [ ${#services_to_start[@]} -gt 0 ]; then
            print_status "Starting services: ${services_to_start[*]}"
            docker-compose up -d "${services_to_start[@]}"
        else
            print_error "No valid services selected."
        fi
    fi
}

# Stop services
stop_services() {
    print_header "Stop Services"
    echo
    
    local running_services=($(get_running_services))
    
    if [ ${#running_services[@]} -eq 0 ]; then
        print_status "No services are currently running."
        return
    fi
    
    print_warning "Stopping services will make them unavailable!"
    echo "Select services to stop (space-separated numbers, 'all', or 'cancel'):"
    local i=1
    for service in "${running_services[@]}"; do
        echo "  $i) $service"
        ((i++))
    done
    echo
    
    read -p "Enter your choice: " selection
    
    if [ "$selection" = "cancel" ]; then
        return
    elif [ "$selection" = "all" ]; then
        print_warning "Stopping all services..."
        docker-compose down
    else
        local services_to_stop=()
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#running_services[@]} ]; then
                services_to_stop+=(${running_services[$((num-1))]})
            fi
        done
        
        if [ ${#services_to_stop[@]} -gt 0 ]; then
            print_status "Stopping services: ${services_to_stop[*]}"
            docker-compose stop "${services_to_stop[@]}"
        else
            print_error "No valid services selected."
        fi
    fi
}

# Restart services
restart_services() {
    print_header "Restart Services"
    echo
    
    local running_services=($(get_running_services))
    
    if [ ${#running_services[@]} -eq 0 ]; then
        print_status "No services are currently running."
        return
    fi
    
    echo "Select services to restart (space-separated numbers or 'all'):"
    local i=1
    for service in "${running_services[@]}"; do
        echo "  $i) $service"
        ((i++))
    done
    echo
    
    read -p "Enter your choice: " selection
    
    if [ "$selection" = "all" ]; then
        print_status "Restarting all services..."
        docker-compose restart
    else
        local services_to_restart=()
        for num in $selection; do
            if [ "$num" -ge 1 ] && [ "$num" -le ${#running_services[@]} ]; then
                services_to_restart+=(${running_services[$((num-1))]})
            fi
        done
        
        if [ ${#services_to_restart[@]} -gt 0 ]; then
            print_status "Restarting services: ${services_to_restart[*]}"
            docker-compose restart "${services_to_restart[@]}"
        else
            print_error "No valid services selected."
        fi
    fi
}

# Update services
update_services() {
    print_header "Update Services"
    echo
    
    print_status "This will pull latest images and restart services..."
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Pulling latest images..."
        docker-compose pull
        
        print_status "Restarting services with new images..."
        docker-compose up -d
        
        print_status "Update completed!"
    else
        print_status "Update cancelled."
    fi
}

# Clean up system
cleanup_system() {
    print_header "System Cleanup"
    echo
    
    print_warning "This will remove unused containers, networks, and images!"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Cleaning up unused containers..."
        docker container prune -f
        
        print_status "Cleaning up unused networks..."
        docker network prune -f
        
        print_status "Cleaning up unused images..."
        docker image prune -f
        
        print_status "Cleanup completed!"
        
        # Show space saved
        print_status "Current disk usage:"
        df -h /
    else
        print_status "Cleanup cancelled."
    fi
}

# Backup configuration
backup_config() {
    print_header "Backup Configuration"
    echo
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    print_status "Creating backup in $backup_dir..."
    
    # Backup configuration files
    cp .env "$backup_dir/" 2>/dev/null || print_warning ".env not found"
    cp docker-compose.yml "$backup_dir/"
    
    # Backup service configurations
    [ -d nginx ] && cp -r nginx "$backup_dir/"
    [ -d prometheus ] && cp -r prometheus "$backup_dir/"
    [ -d grafana ] && cp -r grafana "$backup_dir/"
    [ -d alertmanager ] && cp -r alertmanager "$backup_dir/"
    [ -d loki ] && cp -r loki "$backup_dir/"
    
    # Create archive
    tar -czf "${backup_dir}.tar.gz" -C backups "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    print_status "Backup created: ${backup_dir}.tar.gz"
}

# Show disk usage
show_disk_usage() {
    print_header "Disk Usage Analysis"
    echo
    
    print_service "Docker System Usage:"
    docker system df
    echo
    
    print_service "Volume Usage:"
    docker volume ls -q | xargs docker volume inspect | grep -E "(Name|Mountpoint)" | paste - -
    echo
    
    print_service "Container Sizes:"
    docker ps --size --format "table {{.Names}}\t{{.Size}}"
    echo
    
    print_service "System Disk Usage:"
    df -h
}

# Check service health
check_health() {
    print_header "Service Health Check"
    echo
    
    local running_services=($(get_running_services))
    
    for service in "${running_services[@]}"; do
        local health=$(docker-compose ps "$service" --format json | jq -r '.Health // "unknown"')
        local status=$(docker-compose ps "$service" --format json | jq -r '.State')
        
        if [ "$status" = "running" ]; then
            if [ "$health" = "healthy" ]; then
                echo "  ✅ $service - Running & Healthy"
            elif [ "$health" = "unhealthy" ]; then
                echo "  ❌ $service - Running but Unhealthy"
            else
                echo "  ⚠️  $service - Running (health unknown)"
            fi
        else
            echo "  ❌ $service - Not Running"
        fi
    done
    echo
    
    # Test web endpoints if available
    if [ -f ".env" ]; then
        DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
        
        print_service "Testing Web Endpoints:"
        
        if [[ " ${running_services[@]} " =~ " grafana " ]]; then
            if curl -ks "https://${DOMAIN}/grafana/api/health" >/dev/null 2>&1; then
                echo "  ✅ Grafana API - Responding"
            else
                echo "  ❌ Grafana API - Not responding"
            fi
        fi
        
        if [[ " ${running_services[@]} " =~ " prometheus " ]]; then
            if curl -ks "https://${DOMAIN}/prometheus/-/healthy" >/dev/null 2>&1; then
                echo "  ✅ Prometheus API - Responding"
            else
                echo "  ❌ Prometheus API - Not responding"
            fi
        fi
    fi
    echo
}

# Handle command line arguments
handle_arguments() {
    case "${1:-}" in
        --status)
            show_status
            exit 0
            ;;
        --logs)
            if [ -n "${2:-}" ]; then
                docker-compose logs -f "$2"
            else
                view_logs
            fi
            exit 0
            ;;
        --restart)
            if [ -n "${2:-}" ]; then
                docker-compose restart "$2"
            else
                restart_services
            fi
            exit 0
            ;;
        --update)
            update_services
            exit 0
            ;;
        --cleanup)
            cleanup_system
            exit 0
            ;;
        --backup)
            backup_config
            exit 0
            ;;
        --health)
            check_health
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
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
}

# Show help message
show_help() {
    echo "Observability Stack Management Script"
    echo
    echo "Usage: $0 [OPTIONS] [SERVICE]"
    echo
    echo "Options:"
    echo "  --status         Show current stack status"
    echo "  --logs [service] View logs for service (or select interactively)"
    echo "  --restart [svc]  Restart service (or select interactively)"
    echo "  --update         Update all services with latest images"
    echo "  --cleanup        Clean up unused Docker resources"
    echo "  --backup         Backup configuration files"
    echo "  --health         Check health of all services"
    echo "  --help, -h       Show this help message"
    echo
    echo "Examples:"
    echo "  $0                       # Interactive menu"
    echo "  $0 --status              # Quick status check"
    echo "  $0 --logs grafana        # View Grafana logs"
    echo "  $0 --restart prometheus  # Restart Prometheus"
    echo
}

# Main execution
main() {
    # Handle command line arguments
    if handle_arguments "$@"; then
        # Arguments processed, exit
        exit 0
    else
        # Interactive mode
        show_banner
        
        while true; do
            show_menu
            echo
            read -p "Press Enter to continue..." 
            clear
        done
    fi
}

# Run main function with all arguments
main "$@" 