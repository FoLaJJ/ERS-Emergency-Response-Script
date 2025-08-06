#!/bin/bash

# Process Investigation Module
# Checks for suspicious processes, high CPU usage, hidden processes, and mining processes

process_investigation() {
    print_section "PROCESS INVESTIGATION"
    
    log_message "INFO" "Starting process investigation module" "process"
    
    # Check all running processes
    print_command_info "All Processes Check" "ps -aux" "process"
    output_and_log "=== All Running Processes ===" "process"
    output_and_log "USER\tPID\t%CPU\t%MEM\tVSZ\tRSS\tTTY\tSTAT\tSTART\tTIME\tCOMMAND" "process" "INFO"
    output_and_log "----\t---\t-----\t-----\t---\t---\t---\t----\t-----\t----\t-------" "process" "INFO"
    ps -aux | head -20 | while read line; do
        output_and_log "$line" "process" "INFO"
    done
    echo ""
    
    # Check for high CPU usage processes
    print_command_info "High CPU Usage Check" "ps -aux --sort=-%cpu | head -10" "process"
    output_and_log "=== High CPU Usage Processes (Top 10) ===" "process"
    output_and_log "WARNING: High CPU usage processes:" "process" "WARNING"
    ps -aux --sort=-%cpu | head -10 | while read line; do
        output_and_log "  $line" "process" "WARNING"
    done
    echo ""
    
    # Check for high memory usage processes
    print_command_info "High Memory Usage Check" "ps -aux --sort=-%mem | head -10" "process"
    output_and_log "=== High Memory Usage Processes (Top 10) ===" "process"
    output_and_log "WARNING: High memory usage processes:" "process" "WARNING"
    ps -aux --sort=-%mem | head -10 | while read line; do
        output_and_log "  $line" "process" "WARNING"
    done
    echo ""
    
    # Check for suspicious mining processes
    print_command_info "Mining Processes Check" "ps -aux | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu'" "process"
    output_and_log "=== Suspicious Mining Processes ===" "process"
    local mining_processes=$(ps -aux | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' | grep -v grep)
    if [[ -n "$mining_processes" ]]; then
        output_and_log "CRITICAL: Mining processes found:" "process" "CRITICAL"
        echo "$mining_processes" | while read line; do
            output_and_log "  - $line" "process" "CRITICAL"
        done
        echo "$mining_processes" > "$TEMP_DIR/suspicious_processes.txt"
    else
        output_and_log "No mining processes found" "process" "SUCCESS"
    fi
    echo ""
    
    # Check for processes with unusual names
    print_command_info "Unusual Process Names Check" "ps -aux | grep -E '[0-9a-f]{32}|[a-z]{1,2}[0-9]{1,2}'" "process"
    output_and_log "=== Processes with Unusual Names ===" "process"
    local unusual_processes=$(ps -aux | grep -E '[0-9a-f]{32}|[a-z]{1,2}[0-9]{1,2}' | grep -v grep)
    if [[ -n "$unusual_processes" ]]; then
        output_and_log "WARNING: Processes with unusual names found:" "process" "WARNING"
        echo "$unusual_processes" | while read line; do
            output_and_log "  - $line" "process" "WARNING"
        done
    else
        output_and_log "No processes with unusual names found" "process" "SUCCESS"
    fi
    echo ""
    
    # Check for processes running from unusual locations
    print_command_info "Unusual Process Locations Check" "ps -aux | grep -v '/usr/bin\|/usr/sbin\|/bin\|/sbin'" "process"
    output_and_log "=== Processes Running from Unusual Locations ===" "process"
    local unusual_locations=$(ps -aux | grep -v '/usr/bin\|/usr/sbin\|/bin\|/sbin' | grep -v 'grep\|ps' | head -10)
    if [[ -n "$unusual_locations" ]]; then
        output_and_log "WARNING: Processes running from unusual locations:" "process" "WARNING"
        echo "$unusual_locations" | while read line; do
            output_and_log "  - $line" "process" "WARNING"
        done
    else
        output_and_log "No processes running from unusual locations found" "process" "SUCCESS"
    fi
    echo ""
    
    # Check process tree
    print_command_info "Process Tree Check" "pstree -asp" "process"
    output_and_log "=== Process Tree ===" "process"
    pstree -asp | head -20 | while read line; do
        output_and_log "$line" "process" "INFO"
    done
    echo ""
    
    # Check for hidden processes using unhide
    print_command_info "Hidden Processes Check" "unhide proc" "process"
    output_and_log "=== Hidden Processes Detection ===" "process"
    if command -v unhide >/dev/null 2>&1; then
        output_and_log "Running unhide to detect hidden processes..." "process" "INFO"
        local hidden_processes=$(unhide proc 2>&1)
        if [[ -n "$hidden_processes" ]]; then
            output_and_log "CRITICAL: Hidden processes detected:" "process" "CRITICAL"
            echo "$hidden_processes" | while read line; do
                output_and_log "  - $line" "process" "CRITICAL"
            done
        else
            output_and_log "No hidden processes detected" "process" "SUCCESS"
        fi
    else
        output_and_log "Installing unhide for hidden process detection..." "process" "WARNING"
        apt update && apt install -y unhide
        if command -v unhide >/dev/null 2>&1; then
            output_and_log "Running unhide to detect hidden processes..." "process" "INFO"
            local hidden_processes=$(unhide proc 2>&1)
            if [[ -n "$hidden_processes" ]]; then
                output_and_log "CRITICAL: Hidden processes detected:" "process" "CRITICAL"
                echo "$hidden_processes" | while read line; do
                    output_and_log "  - $line" "process" "CRITICAL"
                done
            else
                output_and_log "No hidden processes detected" "process" "SUCCESS"
            fi
        else
            output_and_log "Failed to install unhide" "process" "ERROR"
        fi
    fi
    echo ""
    
    # Check for processes with network connections
    print_command_info "Processes with Network Connections" "netstat -anp | grep ESTABLISHED" "process"
    output_and_log "=== Processes with Network Connections ===" "process"
    netstat -anp | grep ESTABLISHED | while read line; do
        output_and_log "$line" "process" "INFO"
    done
    echo ""
    
    # Check for processes with open files
    print_command_info "Processes with Open Files" "lsof | head -20" "process"
    output_and_log "=== Processes with Open Files (Top 20) ===" "process"
    lsof 2>/dev/null | head -20 | while read line; do
        output_and_log "$line" "process" "INFO"
    done
    echo ""
    
    # Check for processes with unusual command line arguments
    print_command_info "Unusual Command Line Arguments" "ps -ef | grep -E '--config\|--pool\|--wallet\|--worker'" "process"
    output_and_log "=== Processes with Unusual Command Line Arguments ===" "process"
    local unusual_args=$(ps -ef | grep -E '--config|--pool|--wallet|--worker' | grep -v grep)
    if [[ -n "$unusual_args" ]]; then
        output_and_log "CRITICAL: Processes with suspicious arguments found:" "process" "CRITICAL"
        echo "$unusual_args" | while read line; do
            output_and_log "  - $line" "process" "CRITICAL"
        done
    else
        output_and_log "No processes with suspicious arguments found" "process" "SUCCESS"
    fi
    echo ""
    
    # Check for processes with high priority
    print_command_info "High Priority Processes" "ps -eo pid,ppid,ni,cmd --sort=-ni | head -10" "process"
    output_and_log "=== High Priority Processes ===" "process"
    ps -eo pid,ppid,ni,cmd --sort=-ni | head -10 | while read line; do
        output_and_log "$line" "process" "INFO"
    done
    echo ""
    
    # Check for zombie processes
    print_command_info "Zombie Processes Check" "ps -aux | grep -E 'Z|zombie'" "process"
    output_and_log "=== Zombie Processes ===" "process"
    local zombie_processes=$(ps -aux | grep -E 'Z|zombie' | grep -v grep)
    if [[ -n "$zombie_processes" ]]; then
        output_and_log "WARNING: Zombie processes found:" "process" "WARNING"
        echo "$zombie_processes" | while read line; do
            output_and_log "  - $line" "process" "WARNING"
        done
    else
        output_and_log "No zombie processes found" "process" "SUCCESS"
    fi
    echo ""
    
    # Check for processes with unusual user ownership
    print_command_info "Unusual User Ownership" "ps -aux | grep -v 'root\|daemon\|bin\|sys\|sync\|games\|man\|lp\|mail\|news\|uucp\|proxy\|www-data\|backup\|list\|irc\|gnats\|nobody\|systemd'" "process"
    output_and_log "=== Processes with Unusual User Ownership ===" "process"
    local unusual_users=$(ps -aux | grep -v 'root\|daemon\|bin\|sys\|sync\|games\|man\|lp\|mail\|news\|uucp\|proxy\|www-data\|backup\|list\|irc\|gnats\|nobody\|systemd' | head -10)
    if [[ -n "$unusual_users" ]]; then
        output_and_log "WARNING: Processes with unusual user ownership:" "process" "WARNING"
        echo "$unusual_users" | while read line; do
            output_and_log "  - $line" "process" "WARNING"
        done
    else
        output_and_log "No processes with unusual user ownership found" "process" "SUCCESS"
    fi
    echo ""
    
    log_message "INFO" "Process investigation module completed" "process"
}

# Execute process investigation
process_investigation 