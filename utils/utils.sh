#!/bin/sh
# Utility functions for Emergency Response Script
# All commands should use busybox instead of system commands

# Get script directory and busybox path
# SCRIPT_DIR should be set by the calling script or config.sh before sourcing this file
# If not set, calculate it based on the location of this utils.sh file
if [ -z "$SCRIPT_DIR" ]; then
    # Try to get the directory where this utils.sh file is located
    # Use a method that works even when sourced
    _SCRIPT_PATH="${BASH_SOURCE:-$0}"
    if [ -n "$_SCRIPT_PATH" ] && [ -f "$_SCRIPT_PATH" ] && [ "$(basename "$_SCRIPT_PATH")" = "utils.sh" ]; then
        _UTILS_DIR="$(cd "$(dirname "$_SCRIPT_PATH")" 2>/dev/null && pwd)"
        # Go up one level to get the project root (utils.sh is in utils/ directory)
        SCRIPT_DIR="$(cd "$_UTILS_DIR/.." 2>/dev/null && pwd)"
    elif [ -f "utils/utils.sh" ]; then
        # If we're in the project root
        SCRIPT_DIR="$(pwd)"
    else
        # Fallback to current directory
        SCRIPT_DIR="$(pwd)"
    fi
fi

# Set busybox path
BUSYBOX="${SCRIPT_DIR}/busybox"

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Initialize busybox if not already done
# This function should only be called once, use INIT_BUSYBOX_DONE flag to prevent multiple calls
init_busybox() {
    # Prevent multiple initializations
    if [ "$INIT_BUSYBOX_DONE" = "1" ]; then
        return 0
    fi
    
    if [ ! -f "$BUSYBOX" ]; then
        echo "${RED}Error: busybox not found at $BUSYBOX${NC}" >&2
        exit 1
    fi
    
    # First, try to actually execute busybox to see if it works
    # This is more reliable than just checking -x flag
    if "$BUSYBOX" --help >/dev/null 2>&1; then
        # Busybox can be executed, mark as done and return
        INIT_BUSYBOX_DONE=1
        export INIT_BUSYBOX_DONE
        return 0
    fi
    
    # If execution failed, check permissions and fix if needed
    # Check if busybox has execute permission
    if [ ! -x "$BUSYBOX" ]; then
        echo "${YELLOW}Warning: busybox is not executable, attempting to chmod +x${NC}"
        echo "${YELLOW}Executing: chmod +x $BUSYBOX${NC}"
        
        # Try to make it executable
        if chmod +x "$BUSYBOX" 2>&1; then
            echo "${GREEN}Success: busybox is now executable${NC}"
        else
            CHMOD_ERROR=$?
            echo "${YELLOW}chmod failed with exit code: $CHMOD_ERROR${NC}"
            # If chmod fails, try with sudo (if available and not already root)
            if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
                echo "${YELLOW}Trying with sudo: sudo chmod +x $BUSYBOX${NC}"
                if sudo chmod +x "$BUSYBOX" 2>&1; then
                    echo "${GREEN}Success: busybox is now executable (with sudo)${NC}"
                else
                    echo "${RED}Error: Cannot make busybox executable even with sudo${NC}"
                    echo "${RED}Please run manually: sudo chmod +x $BUSYBOX${NC}"
                    exit 1
                fi
            else
                echo "${RED}Error: Cannot make busybox executable${NC}"
                echo "${RED}Please run: chmod +x $BUSYBOX${NC}"
                if [ "$(id -u)" != "0" ]; then
                    echo "${RED}Or run this script with sudo: sudo $0${NC}"
                fi
                exit 1
            fi
        fi
    fi
    
    # Verify busybox can be executed by actually running it
    if "$BUSYBOX" --help >/dev/null 2>&1; then
        INIT_BUSYBOX_DONE=1
        export INIT_BUSYBOX_DONE
        return 0
    else
        VERIFY_ERROR=$?
        echo "${RED}Error: busybox cannot be executed (exit code: $VERIFY_ERROR)${NC}"
        echo "${YELLOW}Current permissions: $(ls -l "$BUSYBOX" 2>&1)${NC}"
        echo "${YELLOW}File type: $(file "$BUSYBOX" 2>&1 2>/dev/null || echo 'file command not available')${NC}"
        echo "${YELLOW}File system mount options: $(mount | grep "$(df "$BUSYBOX" | tail -1 | awk '{print $1}')" 2>/dev/null || echo 'cannot check mount options')${NC}"
        exit 1
    fi
}

# Safe busybox command wrapper
bb() {
    "$BUSYBOX" "$@" 2>&1
}

# Print colored message
print_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo "${PURPLE}${BOLD}========================================${NC}"
    echo "${PURPLE}${BOLD}$1${NC}"
    echo "${PURPLE}${BOLD}========================================${NC}"
    echo ""
}

print_task() {
    echo "${CYAN}${BOLD}Current Task:${NC} $1"
}

print_command() {
    echo "${WHITE}Current Command:${NC} $1"
}

print_result() {
    echo "${WHITE}Current Result:${NC}"
    echo "$1"
    echo ""
}

# Get current timestamp
get_timestamp() {
    bb date +"%Y%m%d_%H%M%S"
}

# Get current date for display
get_date() {
    bb date +"%Y-%m-%d %H:%M:%S"
}

# Create results directory
create_results_dir() {
    RESULTS_DIR="${SCRIPT_DIR}/results"
    if [ ! -d "$RESULTS_DIR" ]; then
        bb mkdir -p "$RESULTS_DIR"
    fi
    echo "$RESULTS_DIR"
}

# Log to file
log_to_file() {
    local log_file="$1"
    local message="$2"
    
    # Return early if log_file is empty
    if [ -z "$log_file" ]; then
        return 1
    fi
    
    # Ensure log file directory exists
    local log_dir=$(dirname "$log_file")
    if [ ! -d "$log_dir" ]; then
        bb mkdir -p "$log_dir" 2>/dev/null || return 1
    fi
    
    # Create log file if it doesn't exist and write header
    if [ ! -f "$log_file" ]; then
        local timestamp=$(get_date)
        {
            echo "=========================================="
            echo "Investigation Log File"
            echo "Generated: $timestamp"
            echo "=========================================="
            echo ""
        } > "$log_file" 2>/dev/null || return 1
    fi
    
    # Append log message
    local timestamp=$(get_date)
    echo "[$timestamp] $message" >> "$log_file" 2>/dev/null || return 1
}

# Execute command and log
execute_and_log() {
    local task="$1"
    local command="$2"
    local log_file="$3"
    local level="${4:-normal}"  # normal, detailed, minimal
    
    print_task "$task"
    print_command "$command"
    
    local result
    result=$(eval "$command" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_result "$result"
        if [ -n "$log_file" ]; then
            log_to_file "$log_file" "Task: $task"
            log_to_file "$log_file" "Command: $command"
            log_to_file "$log_file" "Result: $result"
            log_to_file "$log_file" "---"
        fi
    else
        print_error "Command failed with exit code $exit_code"
        if [ -n "$log_file" ]; then
            log_to_file "$log_file" "Task: $task (FAILED)"
            log_to_file "$log_file" "Command: $command"
            log_to_file "$log_file" "Error: $result"
            log_to_file "$log_file" "---"
        fi
    fi
    
    return $exit_code
}

# Create table output
create_table() {
    local headers="$1"
    local data="$2"
    
    echo "$headers" | bb awk -F'|' '{
        for(i=1; i<=NF; i++) {
            printf "%-20s", $i
        }
        print ""
    }'
    echo "----------------------------------------------------------------------------"
    echo "$data" | bb awk -F'|' '{
        for(i=1; i<=NF; i++) {
            printf "%-20s", $i
        }
        print ""
    }'
}

# Check if file exists (using busybox)
file_exists() {
    [ -f "$1" ] && return 0 || return 1
}

# Check if directory exists (using busybox)
dir_exists() {
    [ -d "$1" ] && return 0 || return 1
}

# Read file content safely
read_file_safe() {
    local file="$1"
    if file_exists "$file"; then
        bb cat "$file" 2>/dev/null
    else
        echo "File not found: $file"
        return 1
    fi
}

# Generate random password
generate_password() {
    bb awk 'BEGIN {
        srand()
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        password = ""
        for (i = 0; i < 16; i++) {
            password = password substr(chars, int(rand() * length(chars)) + 1, 1)
        }
        print password
    }'
}

# Generate session ID (timestamp + random string)
generate_session_id() {
    local timestamp=$(bb date +%s)
    local random=$(bb awk 'BEGIN {
        srand()
        chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        random = ""
        for (i = 0; i < 16; i++) {
            random = random substr(chars, int(rand() * length(chars)) + 1, 1)
        }
        print random
    }')
    echo "${timestamp}_${random}"
}

# Check investigation level
should_investigate() {
    local level="$1"
    local config_level="${INVESTIGATION_LEVEL:-normal}"
    
    case "$config_level" in
        minimal)
            [ "$level" = "minimal" ] && return 0 || return 1
            ;;
        normal)
            [ "$level" = "minimal" ] || [ "$level" = "normal" ] && return 0 || return 1
            ;;
        detailed)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Note: init_busybox() should be called explicitly by the main script
# Do not call it automatically here to avoid issues with SCRIPT_DIR not being set yet

