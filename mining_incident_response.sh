#!/bin/bash

# Mining Incident Response Script for Ubuntu Systems
# Author: Security Response Team
# Version: 1.0
# Description: Comprehensive mining incident response and investigation script

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$SCRIPT_DIR/incident_response_${TIMESTAMP}.log"
TEMP_DIR="$SCRIPT_DIR/temp"
RESULTS_DIR="$SCRIPT_DIR/results"

# Create necessary directories
mkdir -p "$TEMP_DIR" "$RESULTS_DIR"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local module="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Main log file
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $timestamp: $message" | tee -a "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $timestamp: $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $timestamp: $message" | tee -a "$LOG_FILE"
            ;;
        "CRITICAL")
            echo -e "${RED}[CRITICAL]${NC} $timestamp: $message" | tee -a "$LOG_FILE"
            ;;
        *)
            echo -e "${BLUE}[DEBUG]${NC} $timestamp: $message" | tee -a "$LOG_FILE"
            ;;
    esac
    
    # Module-specific log file
    if [[ -n "$module" ]]; then
        local module_log="$RESULTS_DIR/${module}_${TIMESTAMP}.log"
        echo "[$level] $timestamp: $message" >> "$module_log"
    fi
}

# Error handling function
handle_error() {
    local exit_code=$?
    log_message "ERROR" "Command failed with exit code $exit_code"
    return $exit_code
}

# Set error handling
trap handle_error ERR

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                MINING INCIDENT RESPONSE SCRIPT               ║"
    echo "║                    Ubuntu System Investigation               ║"
    echo "║                        Version 1.0                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print section header
print_section() {
    local section_name="$1"
    echo -e "\n${PURPLE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    $section_name${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════${NC}\n"
}

# Print command execution info
print_command_info() {
    local task="$1"
    local command="$2"
    local module="$3"
    
    echo -e "${BLUE}Current Task:${NC} $task"
    echo -e "${BLUE}Current Command:${NC} $command"
    echo -e "${BLUE}Current Result:${NC}"
    
    # Log to module-specific file
    if [[ -n "$module" ]]; then
        local module_log="$RESULTS_DIR/${module}_${TIMESTAMP}.log"
        echo "" >> "$module_log"
        echo "=== $task ===" >> "$module_log"
        echo "Command: $command" >> "$module_log"
        echo "Result:" >> "$module_log"
    fi
}

# Output function that displays and logs
output_and_log() {
    local message="$1"
    local module="$2"
    local level="${3:-INFO}"
    
    # Display with color
    case $level in
        "CRITICAL")
            echo -e "${RED}$message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}$message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}$message${NC}"
            ;;
        "INFO")
            echo -e "${CYAN}$message${NC}"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
    
    # Log to module file (without color codes)
    if [[ -n "$module" ]]; then
        local module_log="$RESULTS_DIR/${module}_${TIMESTAMP}.log"
        # Remove color codes for log file
        echo "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$module_log"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root"
        echo -e "${RED}Please run this script with sudo privileges${NC}"
        exit 1
    fi
}

# Check system compatibility
check_system() {
    if [[ ! -f /etc/os-release ]]; then
        log_message "ERROR" "Cannot determine operating system"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_message "WARNING" "This script is designed for Ubuntu systems. Current OS: $ID"
    fi
}

# Main execution function
main() {
    print_banner
    log_message "INFO" "Starting mining incident response investigation"
    
    # Check prerequisites
    check_root
    check_system
    
    # Execute investigation modules
    source "$SCRIPT_DIR/modules/user_investigation.sh"
    source "$SCRIPT_DIR/modules/command_investigation.sh"
    source "$SCRIPT_DIR/modules/network_investigation.sh"
    source "$SCRIPT_DIR/modules/process_investigation.sh"
    source "$SCRIPT_DIR/modules/startup_investigation.sh"
    source "$SCRIPT_DIR/modules/cron_investigation.sh"
    source "$SCRIPT_DIR/modules/log_investigation.sh"
    source "$SCRIPT_DIR/modules/system_investigation.sh"
    
    # Generate summary report
    generate_summary_report
    
    log_message "INFO" "Investigation completed. Check results in: $RESULTS_DIR"
    echo -e "${GREEN}Investigation completed successfully!${NC}"
}

# Generate summary report
generate_summary_report() {
    print_section "SUMMARY REPORT"
    
    local summary_file="$RESULTS_DIR/summary_${TIMESTAMP}.txt"
    
    {
        echo "MINING INCIDENT RESPONSE SUMMARY REPORT"
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo "========================================"
        echo ""
        
        if [[ -f "$TEMP_DIR/suspicious_users.txt" ]]; then
            echo "SUSPICIOUS USERS FOUND:"
            cat "$TEMP_DIR/suspicious_users.txt"
            echo ""
        fi
        
        if [[ -f "$TEMP_DIR/suspicious_processes.txt" ]]; then
            echo "SUSPICIOUS PROCESSES FOUND:"
            cat "$TEMP_DIR/suspicious_processes.txt"
            echo ""
        fi
        
        if [[ -f "$TEMP_DIR/suspicious_connections.txt" ]]; then
            echo "SUSPICIOUS NETWORK CONNECTIONS:"
            cat "$TEMP_DIR/suspicious_connections.txt"
            echo ""
        fi
        
        if [[ -f "$TEMP_DIR/suspicious_cron.txt" ]]; then
            echo "SUSPICIOUS CRON JOBS:"
            cat "$TEMP_DIR/suspicious_cron.txt"
            echo ""
        fi
        
    } > "$summary_file"
    
    log_message "INFO" "Summary report generated: $summary_file"
    
    # Create a comprehensive results index
    create_results_index
}

# Create results index file
create_results_index() {
    local index_file="$RESULTS_DIR/results_index_${TIMESTAMP}.txt"
    
    {
        echo "MINING INCIDENT RESPONSE RESULTS INDEX"
        echo "Generated: $(date)"
        echo "======================================"
        echo ""
        echo "LOG FILES:"
        echo "----------"
        ls -la "$RESULTS_DIR"/*.log 2>/dev/null | while read line; do
            echo "  $line"
        done
        echo ""
        echo "SUMMARY FILES:"
        echo "---------------"
        ls -la "$RESULTS_DIR"/*.txt 2>/dev/null | while read line; do
            echo "  $line"
        done
        echo ""
        echo "SUSPICIOUS ITEMS FOUND:"
        echo "----------------------"
        if [[ -f "$TEMP_DIR/suspicious_users.txt" ]]; then
            echo "  - Suspicious users: $(wc -l < "$TEMP_DIR/suspicious_users.txt") entries"
        fi
        if [[ -f "$TEMP_DIR/suspicious_processes.txt" ]]; then
            echo "  - Suspicious processes: $(wc -l < "$TEMP_DIR/suspicious_processes.txt") entries"
        fi
        if [[ -f "$TEMP_DIR/suspicious_connections.txt" ]]; then
            echo "  - Suspicious connections: $(wc -l < "$TEMP_DIR/suspicious_connections.txt") entries"
        fi
        if [[ -f "$TEMP_DIR/suspicious_cron.txt" ]]; then
            echo "  - Suspicious cron jobs: $(wc -l < "$TEMP_DIR/suspicious_cron.txt") entries"
        fi
        echo ""
        echo "INVESTIGATION COMPLETED: $(date)"
    } > "$index_file"
    
    log_message "INFO" "Results index created: $index_file"
}

# Execute main function
main "$@" 