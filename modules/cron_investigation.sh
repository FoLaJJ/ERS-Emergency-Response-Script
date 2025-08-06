#!/bin/bash

# Cron Investigation Module
# Checks for suspicious cron jobs, scheduled tasks, and automated scripts

cron_investigation() {
    print_section "CRON INVESTIGATION"
    
    log_message "INFO" "Starting cron investigation module" "cron"
    
    # Check system cron jobs
    print_command_info "System Cron Jobs Check" "crontab -l" "cron"
    output_and_log "=== System Cron Jobs ===" "cron"
    if crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$'; then
        crontab -l | while read line; do
            output_and_log "$line" "cron" "INFO"
        done
    else
        output_and_log "No system cron jobs found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check user cron jobs
    print_command_info "User Cron Jobs Check" "crontab -u root -l" "cron"
    output_and_log "=== Root User Cron Jobs ===" "cron"
    if crontab -u root -l 2>/dev/null | grep -v '^#' | grep -v '^$'; then
        crontab -u root -l | while read line; do
            output_and_log "$line" "cron" "INFO"
        done
    else
        output_and_log "No root cron jobs found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for suspicious cron jobs
    print_command_info "Suspicious Cron Jobs Check" "crontab -l | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl'" "cron"
    output_and_log "=== Suspicious Cron Jobs ===" "cron"
    local suspicious_cron=$(crontab -l 2>/dev/null | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl')
    if [[ -n "$suspicious_cron" ]]; then
        output_and_log "CRITICAL: Suspicious cron jobs found:" "cron" "CRITICAL"
        echo "$suspicious_cron" | while read line; do
            output_and_log "  - $line" "cron" "CRITICAL"
        done
        echo "$suspicious_cron" > "$TEMP_DIR/suspicious_cron.txt"
    else
        output_and_log "No suspicious cron jobs found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check system cron directories
    print_command_info "System Cron Directories Check" "ls -la /etc/cron.*/" "cron"
    output_and_log "=== System Cron Directories ===" "cron"
    for dir in /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ /etc/cron.monthly/ /etc/cron.weekly/; do
        if [[ -d "$dir" ]]; then
            output_and_log "Directory: $dir" "cron" "INFO"
            ls -la "$dir" | while read line; do
                output_and_log "  $line" "cron" "INFO"
            done
            echo ""
        fi
    done
    
    # Check for suspicious files in cron directories
    print_command_info "Suspicious Files in Cron Directories Check" "find /etc/cron.*/ -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \;" "cron"
    output_and_log "=== Suspicious Files in Cron Directories ===" "cron"
    local suspicious_cron_files=$(find /etc/cron.*/ -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \; 2>/dev/null)
    if [[ -n "$suspicious_cron_files" ]]; then
        output_and_log "CRITICAL: Suspicious files in cron directories found:" "cron" "CRITICAL"
        echo "$suspicious_cron_files" | while read file; do
            output_and_log "  - $file" "cron" "CRITICAL"
            output_and_log "Content:" "cron" "INFO"
            cat "$file" | while read line; do
                output_and_log "    $line" "cron" "INFO"
            done
            echo ""
        done
    else
        output_and_log "No suspicious files in cron directories found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for recently modified cron files
    print_command_info "Recently Modified Cron Files Check" "find /etc/cron.*/ -mtime -7 -type f" "cron"
    output_and_log "=== Recently Modified Cron Files (Last 7 Days) ===" "cron"
    local recent_cron_files=$(find /etc/cron.*/ -mtime -7 -type f 2>/dev/null)
    if [[ -n "$recent_cron_files" ]]; then
        output_and_log "WARNING: Recently modified cron files found:" "cron" "WARNING"
        echo "$recent_cron_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "cron" "WARNING"
        done
    else
        output_and_log "No recently modified cron files found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for cron jobs with unusual permissions
    print_command_info "Unusual Cron File Permissions Check" "find /etc/cron.*/ -perm -o+w -type f" "cron"
    output_and_log "=== Cron Files with Unusual Permissions ===" "cron"
    local unusual_cron_perms=$(find /etc/cron.*/ -perm -o+w -type f 2>/dev/null)
    if [[ -n "$unusual_cron_perms" ]]; then
        output_and_log "CRITICAL: Cron files with unusual permissions found:" "cron" "CRITICAL"
        echo "$unusual_cron_perms" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "cron" "CRITICAL"
        done
    else
        output_and_log "No cron files with unusual permissions found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for hidden cron jobs
    print_command_info "Hidden Cron Jobs Check" "find /etc/cron.*/ -name '.*' -type f" "cron"
    output_and_log "=== Hidden Cron Files ===" "cron"
    local hidden_cron_files=$(find /etc/cron.*/ -name '.*' -type f 2>/dev/null)
    if [[ -n "$hidden_cron_files" ]]; then
        output_and_log "WARNING: Hidden cron files found:" "cron" "WARNING"
        echo "$hidden_cron_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "cron" "WARNING"
        done
    else
        output_and_log "No hidden cron files found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for cron jobs in user directories
    print_command_info "User Cron Jobs Check" "find /home -name 'crontab' -type f" "cron"
    output_and_log "=== User Cron Jobs ===" "cron"
    find /home -name "crontab" -type f 2>/dev/null | while read file; do
        local owner=$(stat -c '%U' "$file" 2>/dev/null)
        output_and_log "User cron file: $file (Owner: $owner)" "cron" "INFO"
        if [[ -s "$file" ]]; then
            output_and_log "Content:" "cron" "INFO"
            cat "$file" | while read line; do
                output_and_log "  $line" "cron" "INFO"
            done
        fi
        echo ""
    done
    
    # Check for cron jobs in root directory
    print_command_info "Root Cron Jobs Check" "find /root -name 'crontab' -type f" "cron"
    output_and_log "=== Root Cron Jobs ===" "cron"
    find /root -name "crontab" -type f 2>/dev/null | while read file; do
        output_and_log "Root cron file: $file" "cron" "INFO"
        if [[ -s "$file" ]]; then
            output_and_log "Content:" "cron" "INFO"
            cat "$file" | while read line; do
                output_and_log "  $line" "cron" "INFO"
            done
        fi
        echo ""
    done
    
    # Check for at jobs
    print_command_info "At Jobs Check" "atq" "cron"
    output_and_log "=== At Jobs ===" "cron"
    local at_jobs=$(atq 2>/dev/null)
    if [[ -n "$at_jobs" ]]; then
        output_and_log "WARNING: At jobs found:" "cron" "WARNING"
        echo "$at_jobs" | while read line; do
            output_and_log "  - $line" "cron" "WARNING"
        done
    else
        output_and_log "No at jobs found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for anacron jobs
    print_command_info "Anacron Jobs Check" "cat /etc/anacrontab" "cron"
    output_and_log "=== Anacron Jobs ===" "cron"
    if [[ -f /etc/anacrontab ]]; then
        cat /etc/anacrontab | while read line; do
            output_and_log "$line" "cron" "INFO"
        done
    else
        output_and_log "No anacrontab file found" "cron" "SUCCESS"
    fi
    echo ""
    
    # Check for systemd timers
    print_command_info "Systemd Timers Check" "systemctl list-timers" "cron"
    output_and_log "=== Systemd Timers ===" "cron"
    systemctl list-timers | while read line; do
        output_and_log "$line" "cron" "INFO"
    done
    echo ""
    
    # Check for suspicious systemd timers
    print_command_info "Suspicious Systemd Timers Check" "systemctl list-timers | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu'" "cron"
    output_and_log "=== Suspicious Systemd Timers ===" "cron"
    local suspicious_timers=$(systemctl list-timers | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu')
    if [[ -n "$suspicious_timers" ]]; then
        output_and_log "CRITICAL: Suspicious systemd timers found:" "cron" "CRITICAL"
        echo "$suspicious_timers" | while read line; do
            output_and_log "  - $line" "cron" "CRITICAL"
        done
    else
        output_and_log "No suspicious systemd timers found" "cron" "SUCCESS"
    fi
    echo ""
    
    log_message "INFO" "Cron investigation module completed" "cron"
}

# Execute cron investigation
cron_investigation 