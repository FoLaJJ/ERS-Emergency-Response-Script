#!/bin/bash

# Log Investigation Module
# Checks for suspicious activities in various log files and command history

log_investigation() {
    print_section "LOG INVESTIGATION"
    
    log_message "INFO" "Starting log investigation module" "log"
    
    # Check auth log for suspicious activities
    print_command_info "Auth Log Check" "cat /var/log/auth.log | tail -20" "log"
    output_and_log "=== Recent Authentication Log Entries ===" "log"
    if [[ -f /var/log/auth.log ]]; then
        cat /var/log/auth.log | tail -20 | while read line; do
            output_and_log "$line" "log" "INFO"
        done
    else
        output_and_log "Auth log file not found" "log" "WARNING"
    fi
    echo ""
    
    # Check for failed login attempts in auth log
    print_command_info "Failed Login Attempts in Auth Log" "cat /var/log/auth.log | grep 'Failed password' | tail -10" "log"
    output_and_log "=== Failed Login Attempts ===" "log"
    if [[ -f /var/log/auth.log ]]; then
        local failed_logins=$(cat /var/log/auth.log | grep "Failed password" | tail -10)
        if [[ -n "$failed_logins" ]]; then
            output_and_log "WARNING: Recent failed login attempts:" "log" "WARNING"
            echo "$failed_logins" | while read line; do
                output_and_log "  $line" "log" "WARNING"
            done
        else
            output_and_log "No recent failed login attempts found" "log" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check for successful logins in auth log
    print_command_info "Successful Logins in Auth Log" "cat /var/log/auth.log | grep 'Accepted password' | tail -10" "log"
    output_and_log "=== Successful Logins ===" "log"
    if [[ -f /var/log/auth.log ]]; then
        local successful_logins=$(cat /var/log/auth.log | grep "Accepted password" | tail -10)
        if [[ -n "$successful_logins" ]]; then
            output_and_log "Recent successful logins:" "log" "INFO"
            echo "$successful_logins" | while read line; do
                output_and_log "  $line" "log" "INFO"
            done
        else
            output_and_log "No recent successful logins found" "log" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check syslog for suspicious activities
    print_command_info "Syslog Check" "cat /var/log/syslog | tail -20" "log"
    output_and_log "=== Recent Syslog Entries ===" "log"
    if [[ -f /var/log/syslog ]]; then
        cat /var/log/syslog | tail -20 | while read line; do
            output_and_log "$line" "log" "INFO"
        done
    else
        output_and_log "Syslog file not found" "log" "WARNING"
    fi
    echo ""
    
    # Check for suspicious activities in syslog
    print_command_info "Suspicious Activities in Syslog" "cat /var/log/syslog | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10" "log"
    output_and_log "=== Suspicious Activities in Syslog ===" "log"
    if [[ -f /var/log/syslog ]]; then
        local suspicious_syslog=$(cat /var/log/syslog | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10)
        if [[ -n "$suspicious_syslog" ]]; then
            output_and_log "CRITICAL: Suspicious activities in syslog:" "log" "CRITICAL"
            echo "$suspicious_syslog" | while read line; do
                output_and_log "  $line" "log" "CRITICAL"
            done
        else
            output_and_log "No suspicious activities found in syslog" "log" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check messages log
    print_command_info "Messages Log Check" "cat /var/log/messages | tail -20" "log"
    output_and_log "=== Recent Messages Log Entries ===" "log"
    if [[ -f /var/log/messages ]]; then
        cat /var/log/messages | tail -20 | while read line; do
            output_and_log "$line" "log" "INFO"
        done
    else
        output_and_log "Messages log file not found" "log" "WARNING"
    fi
    echo ""
    
    # Check for suspicious activities in messages log
    print_command_info "Suspicious Activities in Messages Log" "cat /var/log/messages | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10" "log"
    output_and_log "=== Suspicious Activities in Messages Log ===" "log"
    if [[ -f /var/log/messages ]]; then
        local suspicious_messages=$(cat /var/log/messages | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10)
        if [[ -n "$suspicious_messages" ]]; then
            output_and_log "CRITICAL: Suspicious activities in messages log:" "log" "CRITICAL"
            echo "$suspicious_messages" | while read line; do
                output_and_log "  $line" "log" "CRITICAL"
            done
        else
            output_and_log "No suspicious activities found in messages log" "log" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check kernel log
    print_command_info "Kernel Log Check" "dmesg | tail -20" "log"
    output_and_log "=== Recent Kernel Log Entries ===" "log"
    dmesg | tail -20 | while read line; do
        output_and_log "$line" "log" "INFO"
    done
    echo ""
    
    # Check for suspicious activities in kernel log
    print_command_info "Suspicious Activities in Kernel Log" "dmesg | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10" "log"
    output_and_log "=== Suspicious Activities in Kernel Log ===" "log"
    local suspicious_kernel=$(dmesg | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl' | tail -10)
    if [[ -n "$suspicious_kernel" ]]; then
        output_and_log "CRITICAL: Suspicious activities in kernel log:" "log" "CRITICAL"
        echo "$suspicious_kernel" | while read line; do
            output_and_log "  $line" "log" "CRITICAL"
        done
    else
        output_and_log "No suspicious activities found in kernel log" "log" "SUCCESS"
    fi
    echo ""
    
    # Check command history
    print_command_info "Command History Check" "history" "log"
    output_and_log "=== Recent Command History ===" "log"
    if [[ -f ~/.bash_history ]]; then
        tail -20 ~/.bash_history | while read line; do
            output_and_log "$line" "log" "INFO"
        done
    else
        output_and_log "Bash history file not found" "log" "WARNING"
    fi
    echo ""
    
    # Check for suspicious commands in history
    print_command_info "Suspicious Commands in History" "history | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl'" "log"
    output_and_log "=== Suspicious Commands in History ===" "log"
    local suspicious_history=$(history | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl')
    if [[ -n "$suspicious_history" ]]; then
        output_and_log "CRITICAL: Suspicious commands in history:" "log" "CRITICAL"
        echo "$suspicious_history" | while read line; do
            output_and_log "  $line" "log" "CRITICAL"
        done
    else
        output_and_log "No suspicious commands found in history" "log" "SUCCESS"
    fi
    echo ""
    
    # Check user command history files
    print_command_info "User Command History Files Check" "find /home -name '.bash_history' -type f" "log"
    output_and_log "=== User Command History Files ===" "log"
    find /home -name ".bash_history" -type f 2>/dev/null | while read file; do
        local owner=$(stat -c '%U' "$file" 2>/dev/null)
        output_and_log "User history file: $file (Owner: $owner)" "log" "INFO"
        if [[ -s "$file" ]]; then
            output_and_log "Recent commands:" "log" "INFO"
            tail -10 "$file" | while read line; do
                output_and_log "  $line" "log" "INFO"
            done
        fi
        echo ""
    done
    
    # Check root command history
    print_command_info "Root Command History Check" "cat /root/.bash_history | tail -20" "log"
    output_and_log "=== Root Command History ===" "log"
    if [[ -f /root/.bash_history ]]; then
        tail -20 /root/.bash_history | while read line; do
            output_and_log "$line" "log" "INFO"
        done
    else
        output_and_log "Root bash history file not found" "log" "WARNING"
    fi
    echo ""
    
    # Check for suspicious commands in root history
    print_command_info "Suspicious Commands in Root History" "cat /root/.bash_history | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl'" "log"
    output_and_log "=== Suspicious Commands in Root History ===" "log"
    if [[ -f /root/.bash_history ]]; then
        local suspicious_root_history=$(cat /root/.bash_history | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu\|wget\|curl')
        if [[ -n "$suspicious_root_history" ]]; then
            output_and_log "CRITICAL: Suspicious commands in root history:" "log" "CRITICAL"
            echo "$suspicious_root_history" | while read line; do
                output_and_log "  $line" "log" "CRITICAL"
            done
        else
            output_and_log "No suspicious commands found in root history" "log" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check for log files with unusual permissions
    print_command_info "Unusual Log File Permissions Check" "find /var/log -perm -o+w -type f" "log"
    output_and_log "=== Log Files with Unusual Permissions ===" "log"
    local unusual_log_perms=$(find /var/log -perm -o+w -type f 2>/dev/null)
    if [[ -n "$unusual_log_perms" ]]; then
        output_and_log "CRITICAL: Log files with unusual permissions found:" "log" "CRITICAL"
        echo "$unusual_log_perms" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "log" "CRITICAL"
        done
    else
        output_and_log "No log files with unusual permissions found" "log" "SUCCESS"
    fi
    echo ""
    
    # Check for recently modified log files
    print_command_info "Recently Modified Log Files Check" "find /var/log -mtime -7 -type f" "log"
    output_and_log "=== Recently Modified Log Files (Last 7 Days) ===" "log"
    local recent_log_files=$(find /var/log -mtime -7 -type f 2>/dev/null)
    if [[ -n "$recent_log_files" ]]; then
        output_and_log "WARNING: Recently modified log files found:" "log" "WARNING"
        echo "$recent_log_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "log" "WARNING"
        done
    else
        output_and_log "No recently modified log files found" "log" "SUCCESS"
    fi
    echo ""
    
    # Check for log files with suspicious content
    print_command_info "Log Files with Suspicious Content Check" "find /var/log -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \;" "log"
    output_and_log "=== Log Files with Suspicious Content ===" "log"
    local suspicious_log_files=$(find /var/log -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \; 2>/dev/null)
    if [[ -n "$suspicious_log_files" ]]; then
        output_and_log "CRITICAL: Log files with suspicious content found:" "log" "CRITICAL"
        echo "$suspicious_log_files" | while read file; do
            output_and_log "  - $file" "log" "CRITICAL"
            output_and_log "Content:" "log" "INFO"
            grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' "$file" | head -5 | while read line; do
                output_and_log "    $line" "log" "INFO"
            done
            echo ""
        done
    else
        output_and_log "No log files with suspicious content found" "log" "SUCCESS"
    fi
    echo ""
    
    log_message "INFO" "Log investigation module completed" "log"
}

# Execute log investigation
log_investigation 