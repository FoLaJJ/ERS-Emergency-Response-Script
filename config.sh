#!/bin/sh
# Configuration file for Emergency Response Script

# ============================================================================
# Investigation Level Configuration
# ============================================================================
# Set the investigation level by modifying the value below.
# Available options: minimal, normal, detailed
#
# Investigation Levels:
# ---------------------
# minimal  - Minimal investigation mode
#           * Only performs critical security checks
#           * Fastest execution time
#           * Smallest log file size
#           * Suitable for: Quick security audits, resource-constrained systems
#           * Checks: Basic user accounts, critical processes, essential network connections
#
# normal   - Standard investigation mode (RECOMMENDED)
#           * Performs standard security checks
#           * Balanced execution time and completeness
#           * Moderate log file size
#           * Suitable for: Regular security investigations, production systems
#           * Checks: All minimal checks + command history, startup items, cron jobs, system logs
#
# detailed - Detailed investigation mode
#           * Performs comprehensive security checks
#           * Longest execution time (may take several minutes)
#           * Largest log file size (may generate hundreds of MB)
#           * Suitable for: Deep security analysis, forensic investigations
#           * Checks: All normal checks + detailed process analysis, extensive log scanning,
#                     file system checks, hidden process detection, comprehensive network analysis
#
# To change the investigation level, modify the value below:
#   INVESTIGATION_LEVEL="minimal"    - For quick checks
#   INVESTIGATION_LEVEL="normal"     - For standard checks (default)
#   INVESTIGATION_LEVEL="detailed"   - For comprehensive checks
#
# Note: Modify the value below to change the investigation level.
# This is the primary way to configure the investigation level.
# ============================================================================

# Set investigation level
# Change this value to "minimal", "normal", or "detailed" as needed
INVESTIGATION_LEVEL="normal"

# Results directory
# SCRIPT_DIR should be set by the calling script before sourcing this file
# If not set, calculate it based on the location of this config.sh file
if [ -z "$SCRIPT_DIR" ]; then
    # Try to get the directory where this config.sh file is located
    # Use a method that works even when sourced
    _SCRIPT_PATH="${BASH_SOURCE:-$0}"
    if [ -n "$_SCRIPT_PATH" ] && [ -f "$_SCRIPT_PATH" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$_SCRIPT_PATH")" 2>/dev/null && pwd)"
    elif [ -f "./config.sh" ]; then
        # If we're in the project root
        SCRIPT_DIR="$(pwd)"
    else
        # Fallback: try to find config.sh
        SCRIPT_DIR="$(pwd)"
    fi
fi
RESULTS_DIR="${SCRIPT_DIR}/results"

# Web server configuration
# Port can be changed by setting WEB_PORT environment variable
# Example: WEB_PORT=10086 ./start_web_viewer.sh
WEB_PORT="${WEB_PORT:-10086}"
WEB_DIR="${SCRIPT_DIR}/web_output"

# Busybox path
BUSYBOX="${SCRIPT_DIR}/busybox"

# System detection
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
    elif [ -f /etc/redhat-release ]; then
        OS_NAME="rhel"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    else
        OS_NAME="unknown"
        OS_VERSION="unknown"
    fi
    echo "$OS_NAME"
}

# Get system type
SYSTEM_TYPE=$(detect_system)

# Log file paths (will be set with timestamp in main script)
# These variables are set by set_log_paths() function in the main script
# We do NOT initialize them here to avoid overwriting values when modules source this file
# If a module sources this file and LOG_* variables are already set (exported),
# they will retain their values. If not set, they will remain unset (which is fine
# for modules executed directly, as they will set their own paths).

# Set log file paths with timestamp
set_log_paths() {
    local timestamp="$1"
    LOG_USER="${RESULTS_DIR}/user_${timestamp}.log"
    LOG_COMMAND="${RESULTS_DIR}/command_${timestamp}.log"
    LOG_NETWORK="${RESULTS_DIR}/network_${timestamp}.log"
    LOG_PROCESS="${RESULTS_DIR}/process_${timestamp}.log"
    LOG_STARTUP="${RESULTS_DIR}/startup_${timestamp}.log"
    LOG_CRON="${RESULTS_DIR}/cron_${timestamp}.log"
    LOG_LOG="${RESULTS_DIR}/log_${timestamp}.log"
    LOG_SYSTEM="${RESULTS_DIR}/system_${timestamp}.log"
    LOG_SUMMARY="${RESULTS_DIR}/summary_${timestamp}.txt"
    LOG_INDEX="${RESULTS_DIR}/results_index_${timestamp}.txt"
    
    # Export log file paths so they are available to sourced modules
    export LOG_USER LOG_COMMAND LOG_NETWORK LOG_PROCESS
    export LOG_STARTUP LOG_CRON LOG_LOG LOG_SYSTEM LOG_SUMMARY LOG_INDEX
}

# Export variables
export INVESTIGATION_LEVEL
export RESULTS_DIR
export WEB_PORT
export WEB_DIR
export BUSYBOX
export SYSTEM_TYPE
# Only export LOG_* variables if they are set (to avoid overwriting with empty values)
[ -n "$LOG_USER" ] && export LOG_USER
[ -n "$LOG_COMMAND" ] && export LOG_COMMAND
[ -n "$LOG_NETWORK" ] && export LOG_NETWORK
[ -n "$LOG_PROCESS" ] && export LOG_PROCESS
[ -n "$LOG_STARTUP" ] && export LOG_STARTUP
[ -n "$LOG_CRON" ] && export LOG_CRON
[ -n "$LOG_LOG" ] && export LOG_LOG
[ -n "$LOG_SYSTEM" ] && export LOG_SYSTEM
[ -n "$LOG_SUMMARY" ] && export LOG_SUMMARY
[ -n "$LOG_INDEX" ] && export LOG_INDEX

