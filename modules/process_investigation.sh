#!/bin/sh
# Process Investigation Module
# Checks suspicious processes, high CPU usage, hidden processes, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_processes() {
    local log_file="$LOG_PROCESS"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_PROCESS is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Process Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Process Investigation Module"
    
    # Check all processes
    if should_investigate "minimal"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check all processes (ps aux)" \
                "ps aux 2>/dev/null | bb head -100" \
                "$log_file" "minimal"
        else
            execute_and_log "Check processes from /proc" \
                "bb ls -d /proc/[0-9]* 2>/dev/null | bb head -50" \
                "$log_file" "minimal"
        fi
    fi
    
    # Check processes sorted by CPU usage
    if should_investigate "normal"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check top CPU consuming processes" \
                "ps aux 2>/dev/null | bb sort -k3 -rn | bb head -20" \
                "$log_file" "normal"
        fi
    fi
    
    # Check processes sorted by memory usage
    if should_investigate "normal"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check top memory consuming processes" \
                "ps aux 2>/dev/null | bb sort -k4 -rn | bb head -20" \
                "$log_file" "normal"
        fi
    fi
    
    # Check process tree
    if should_investigate "normal"; then
        if bb which pstree >/dev/null 2>&1; then
            execute_and_log "Check process tree" \
                "pstree -asp 2>/dev/null | bb head -100" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for suspicious process names
    if should_investigate "normal"; then
        local suspicious_patterns="miner xmrig ccminer cpuminer minerd"
        if bb which ps >/dev/null 2>&1; then
            for pattern in $suspicious_patterns; do
                execute_and_log "Check for processes matching pattern: $pattern" \
                    "ps aux 2>/dev/null | bb grep -i $pattern | bb grep -v grep || echo 'No processes found'" \
                    "$log_file" "normal"
            done
        fi
    fi
    
    # Check processes with network connections
    if should_investigate "normal"; then
        if bb which netstat >/dev/null 2>&1; then
            execute_and_log "Check processes with network connections" \
                "bb netstat -anp 2>/dev/null | bb grep ESTAB | bb head -50" \
                "$log_file" "normal"
        elif bb which ss >/dev/null 2>&1; then
            execute_and_log "Check processes with network connections (ss)" \
                "ss -anp 2>/dev/null | bb grep ESTAB | bb head -50" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for processes running from suspicious locations
    if should_investigate "detailed"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check processes running from /tmp or /var/tmp" \
                "ps aux 2>/dev/null | bb awk '{print \$11}' | bb grep -E '^/tmp|^/var/tmp' | bb sort -u" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check process command lines
    if should_investigate "detailed"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check process command lines (full)" \
                "ps auxww 2>/dev/null | bb head -50" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check for processes with suspicious parent processes
    if should_investigate "detailed"; then
        if bb which ps >/dev/null 2>&1; then
            execute_and_log "Check process parent-child relationships" \
                "ps -ef 2>/dev/null | bb awk '{print \$2, \$3, \$8}' | bb head -50" \
                "$log_file" "detailed"
        fi
    fi
    
    # Recommendation to use unhide
    if should_investigate "detailed"; then
        print_info "Recommendation: Install and use 'unhide' to detect hidden processes"
        print_info "Command: apt install unhide && unhide proc"
        log_to_file "$log_file" "INFO: Recommendation to use unhide for hidden process detection"
    fi
    
    # Check /proc for process information
    if should_investigate "detailed"; then
        execute_and_log "Check /proc for process directories" \
            "bb ls -ld /proc/[0-9]* 2>/dev/null | bb wc -l" \
            "$log_file" "detailed"
        
        local proc_count=$(bb ls -d /proc/[0-9]* 2>/dev/null | bb wc -l)
        echo "Total processes found: $proc_count"
    fi
    
    # Check for processes with deleted binaries
    if should_investigate "detailed"; then
        if bb which lsof >/dev/null 2>&1; then
            execute_and_log "Check for processes with deleted binaries (lsof)" \
                "lsof 2>/dev/null | bb grep deleted | bb head -20" \
                "$log_file" "detailed"
        fi
    fi
    
    # Summary
    print_section "Process Investigation Summary"
    local process_count=0
    if bb which ps >/dev/null 2>&1; then
        process_count=$(ps aux 2>/dev/null | bb wc -l)
    else
        process_count=$(bb ls -d /proc/[0-9]* 2>/dev/null | bb wc -l)
    fi
    
    echo "Total processes: $process_count"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Total processes: $process_count"
    
    print_success "Process investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "process_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_processes
fi

