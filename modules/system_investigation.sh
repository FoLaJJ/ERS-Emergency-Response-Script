#!/bin/sh
# System Investigation Module
# Checks system information, filesystem, suspicious files, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_system() {
    local log_file="$LOG_SYSTEM"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_SYSTEM is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "System Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "System Investigation Module"
    
    # Check system information
    if should_investigate "minimal"; then
        execute_and_log "Check system uptime" \
            "bb cat /proc/uptime" \
            "$log_file" "minimal"
        
        execute_and_log "Check system load average" \
            "bb cat /proc/loadavg" \
            "$log_file" "minimal"
    fi
    
    # Check OS information
    if should_investigate "minimal"; then
        if [ -f /etc/os-release ]; then
            execute_and_log "Check OS release information" \
                "bb cat /etc/os-release" \
                "$log_file" "minimal"
        fi
        
        execute_and_log "Check kernel version" \
            "bb uname -a" \
            "$log_file" "minimal"
    fi
    
    # Check disk usage
    if should_investigate "normal"; then
        if bb which df >/dev/null 2>&1; then
            execute_and_log "Check disk usage" \
                "df -h 2>/dev/null || bb df -h" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for large files
    if should_investigate "detailed"; then
        execute_and_log "Check for large files in /tmp (top 20)" \
            "bb find /tmp -type f -size +10M -exec bb ls -lh {} \; 2>/dev/null | bb head -20" \
            "$log_file" "detailed"
        
        execute_and_log "Check for large files in /var/tmp (top 20)" \
            "bb find /var/tmp -type f -size +10M -exec bb ls -lh {} \; 2>/dev/null | bb head -20" \
            "$log_file" "detailed"
    fi
    
    # Check /tmp for suspicious files
    if should_investigate "normal"; then
        execute_and_log "Check /tmp directory contents" \
            "bb ls -la /tmp/ 2>/dev/null | bb head -50" \
            "$log_file" "normal"
    fi
    
    # Check /var/tmp for suspicious files
    if should_investigate "normal"; then
        execute_and_log "Check /var/tmp directory contents" \
            "bb ls -la /var/tmp/ 2>/dev/null | bb head -50" \
            "$log_file" "normal"
    fi
    
    # Check for suspicious file permissions
    if should_investigate "detailed"; then
        execute_and_log "Check for world-writable files in sensitive directories" \
            "bb find /etc /usr/bin /usr/sbin -type f -perm -002 2>/dev/null | bb head -20" \
            "$log_file" "detailed"
    fi
    
    # Check for setuid files
    if should_investigate "normal"; then
        execute_and_log "Check for setuid files in common directories" \
            "bb find /usr/bin /usr/sbin /bin /sbin -type f -perm -4000 2>/dev/null | bb head -30" \
            "$log_file" "normal"
    fi
    
    # Check for recently modified files
    if should_investigate "detailed"; then
        execute_and_log "Check recently modified files in /etc (last 7 days)" \
            "bb find /etc -type f -mtime -7 -exec bb ls -lctr {} \; 2>/dev/null | bb head -30" \
            "$log_file" "detailed"
    fi
    
    # Check for hidden files
    if should_investigate "normal"; then
        execute_and_log "Check for hidden files in root directory" \
            "bb ls -la /root/ | bb grep '^\.' | bb head -20" \
            "$log_file" "normal"
    fi
    
    # Check mounted filesystems
    if should_investigate "normal"; then
        execute_and_log "Check mounted filesystems" \
            "bb cat /proc/mounts" \
            "$log_file" "normal"
    fi
    
    # Check for suspicious file names
    if should_investigate "detailed"; then
        local suspicious_names="miner xmrig ccminer cpuminer minerd"
        for name in $suspicious_names; do
            execute_and_log "Check for files containing: $name" \
                "bb find /tmp /var/tmp /home -iname '*$name*' 2>/dev/null | bb head -20" \
                "$log_file" "detailed"
        done
    fi
    
    # Check memory information
    if should_investigate "normal"; then
        execute_and_log "Check memory information" \
            "bb cat /proc/meminfo | bb head -20" \
            "$log_file" "normal"
    fi
    
    # Check CPU information
    if should_investigate "normal"; then
        execute_and_log "Check CPU information" \
            "bb cat /proc/cpuinfo | bb head -30" \
            "$log_file" "normal"
    fi
    
    # Check for suspicious environment variables
    if should_investigate "normal"; then
        execute_and_log "Check environment variables" \
            "env | bb sort" \
            "$log_file" "normal"
    fi
    
    # Check package manager logs for suspicious installations
    if should_investigate "detailed"; then
        if [ -f /var/log/apt/history.log ]; then
            execute_and_log "Check recent package installations (apt)" \
                "bb tail -50 /var/log/apt/history.log 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Summary
    print_section "System Investigation Summary"
    local disk_usage=""
    if bb which df >/dev/null 2>&1; then
        disk_usage=$(df -h / 2>/dev/null | bb tail -1 | bb awk '{print $5}')
    fi
    
    echo "Root filesystem usage: $disk_usage"
    echo "System type: $SYSTEM_TYPE"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Disk usage: $disk_usage, System: $SYSTEM_TYPE"
    
    print_success "System investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "system_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_system
fi

