#!/bin/bash

# GrowERP MCP Server Deployment Script
# This script deploys and configures the MCP server in a Moqui environment

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_DIR="$(dirname "$SCRIPT_DIR")"
MOQUI_HOME="${MOQUI_HOME:-$(cd "$COMPONENT_DIR/../../.." && pwd)}"
MCP_PORT="${MCP_PORT:-3000}"
DEBUG_MODE="${DEBUG_MODE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
GrowERP MCP Server Deployment Script

Usage: $0 [OPTIONS] COMMAND

Commands:
    install     Install the MCP server component
    start       Start the MCP server
    stop        Stop the MCP server
    restart     Restart the MCP server
    status      Check MCP server status
    test        Run tests
    deploy      Full deployment (install + start)
    clean       Clean build artifacts
    help        Show this help

Options:
    -p, --port PORT     MCP server port (default: 3000)
    -d, --debug         Enable debug mode
    -h, --help          Show this help
    --moqui-home PATH   Moqui home directory
    --skip-tests        Skip running tests during deployment
    --force             Force installation even if already installed

Examples:
    $0 deploy                    # Full deployment with defaults
    $0 start -p 3001 -d         # Start with custom port and debug
    $0 install --force          # Force reinstallation
    $0 test                     # Run tests only

EOF
}

# Parse command line arguments
COMMAND=""
SKIP_TESTS=false
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            MCP_PORT="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG_MODE=true
            shift
            ;;
        --moqui-home)
            MOQUI_HOME="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        install|start|stop|restart|status|test|deploy|clean)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate command
if [[ -z "$COMMAND" ]]; then
    log_error "No command specified"
    show_help
    exit 1
fi

# Validate environment
check_environment() {
    log_info "Checking environment..."
    
    # Check if we're in the right directory
    if [[ ! -f "$COMPONENT_DIR/component.xml" ]]; then
        log_error "Not in MCP server component directory"
        exit 1
    fi
    
    # Check Moqui home
    if [[ ! -f "$MOQUI_HOME/build.gradle" ]]; then
        log_error "Invalid Moqui home directory: $MOQUI_HOME"
        exit 1
    fi
    
    # Check Java
    if ! command -v java &> /dev/null; then
        log_error "Java not found. Please install Java 11 or later."
        exit 1
    fi
    
    # Check Gradle
    if [[ ! -f "$MOQUI_HOME/gradlew" ]]; then
        log_error "Gradle wrapper not found in Moqui directory"
        exit 1
    fi
    
    log_success "Environment checks passed"
}

# Install the MCP server component
install_component() {
    log_info "Installing MCP server component..."
    
    # Check if already installed
    if [[ -f "$COMPONENT_DIR/.installed" && "$FORCE_INSTALL" != "true" ]]; then
        log_warning "MCP server already installed. Use --force to reinstall."
        return 0
    fi
    
    # Create directories
    mkdir -p "$COMPONENT_DIR/build"
    mkdir -p "$COMPONENT_DIR/config"
    mkdir -p "$COMPONENT_DIR/data"
    mkdir -p "$COMPONENT_DIR/logs"
    
    # Copy configuration example if it doesn't exist
    if [[ ! -f "$COMPONENT_DIR/config/mcp-server.conf" ]]; then
        if [[ -f "$COMPONENT_DIR/config/mcp-server.conf.example" ]]; then
            cp "$COMPONENT_DIR/config/mcp-server.conf.example" "$COMPONENT_DIR/config/mcp-server.conf"
            log_info "Created default configuration file"
        fi
    fi
    
    # Build the component
    log_info "Building MCP server component..."
    cd "$COMPONENT_DIR"
    "$MOQUI_HOME/gradlew" build
    
    if [[ $? -eq 0 ]]; then
        # Mark as installed
        echo "$(date)" > "$COMPONENT_DIR/.installed"
        log_success "MCP server component installed successfully"
    else
        log_error "Failed to build MCP server component"
        exit 1
    fi
}

# Run tests
run_tests() {
    log_info "Running MCP server tests..."
    
    cd "$COMPONENT_DIR"
    "$MOQUI_HOME/gradlew" test
    
    if [[ $? -eq 0 ]]; then
        log_success "All tests passed"
    else
        log_error "Tests failed"
        exit 1
    fi
}

# Start MCP server
start_server() {
    log_info "Starting MCP server on port $MCP_PORT..."
    
    # Check if Moqui is running
    if ! curl -f http://localhost:8080/status &> /dev/null; then
        log_warning "Moqui doesn't appear to be running. Starting Moqui first..."
        cd "$MOQUI_HOME"
        "./gradlew" run &
        
        # Wait for Moqui to start
        log_info "Waiting for Moqui to start..."
        for i in {1..30}; do
            if curl -f http://localhost:8080/status &> /dev/null; then
                log_success "Moqui is running"
                break
            fi
            sleep 2
            if [[ $i -eq 30 ]]; then
                log_error "Moqui failed to start within 60 seconds"
                exit 1
            fi
        done
    fi
    
    # Start MCP server via REST API
    RESPONSE=$(curl -s -X POST "http://localhost:8080/mcp/server" \
        -H "Content-Type: application/json" \
        -d "{\"action\": \"start\", \"port\": $MCP_PORT, \"debug\": $DEBUG_MODE}")
    
    if [[ $? -eq 0 ]]; then
        log_success "MCP server start request sent"
        log_info "Response: $RESPONSE"
        
        # Wait for server to be ready
        log_info "Waiting for MCP server to be ready..."
        for i in {1..15}; do
            if curl -f "http://localhost:$MCP_PORT/health" &> /dev/null; then
                log_success "MCP server is ready on port $MCP_PORT"
                return 0
            fi
            sleep 1
        done
        
        log_warning "MCP server may not be ready yet. Check logs for details."
    else
        log_error "Failed to start MCP server"
        exit 1
    fi
}

# Stop MCP server
stop_server() {
    log_info "Stopping MCP server..."
    
    RESPONSE=$(curl -s -X POST "http://localhost:8080/mcp/server" \
        -H "Content-Type: application/json" \
        -d '{"action": "stop"}')
    
    if [[ $? -eq 0 ]]; then
        log_success "MCP server stop request sent"
        log_info "Response: $RESPONSE"
    else
        log_error "Failed to stop MCP server"
        exit 1
    fi
}

# Check server status
check_status() {
    log_info "Checking MCP server status..."
    
    # Check via Moqui
    RESPONSE=$(curl -s "http://localhost:8080/mcp/server" \
        -H "Content-Type: application/json" \
        -d '{"action": "list"}')
    
    if [[ $? -eq 0 ]]; then
        log_info "Server status from Moqui:"
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    else
        log_warning "Could not get status from Moqui"
    fi
    
    # Check direct health endpoint
    if curl -f "http://localhost:$MCP_PORT/health" &> /dev/null; then
        HEALTH=$(curl -s "http://localhost:$MCP_PORT/health")
        log_success "MCP server is healthy"
        echo "$HEALTH" | jq . 2>/dev/null || echo "$HEALTH"
    else
        log_warning "MCP server health check failed"
    fi
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."
    
    cd "$COMPONENT_DIR"
    "$MOQUI_HOME/gradlew" clean
    
    rm -rf build/
    rm -rf logs/*
    rm -f .installed
    
    log_success "Build artifacts cleaned"
}

# Full deployment
deploy() {
    log_info "Starting full MCP server deployment..."
    
    install_component
    
    if [[ "$SKIP_TESTS" != "true" ]]; then
        run_tests
    fi
    
    start_server
    
    log_success "MCP server deployment completed successfully!"
    log_info "Server is running on http://localhost:$MCP_PORT"
    log_info "Health check: http://localhost:$MCP_PORT/health"
    log_info "Moqui integration: http://localhost:8080/mcp/"
}

# Main execution
main() {
    log_info "GrowERP MCP Server Deployment"
    log_info "Command: $COMMAND"
    log_info "Port: $MCP_PORT"
    log_info "Debug: $DEBUG_MODE"
    log_info "Moqui Home: $MOQUI_HOME"
    echo
    
    check_environment
    
    case "$COMMAND" in
        install)
            install_component
            ;;
        start)
            start_server
            ;;
        stop)
            stop_server
            ;;
        restart)
            stop_server
            sleep 2
            start_server
            ;;
        status)
            check_status
            ;;
        test)
            run_tests
            ;;
        deploy)
            deploy
            ;;
        clean)
            clean_build
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
