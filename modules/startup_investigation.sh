#!/bin/bash

# Startup Investigation Module
# Checks for suspicious startup services, systemd services, and auto-start configurations

startup_investigation() {
    print_section "STARTUP INVESTIGATION"
    
    log_message "INFO" "Starting startup investigation module" "startup"
    
    # Check systemd enabled services
    print_command_info "Systemd Enabled Services Check" "systemctl list-unit-files --type=service | grep enabled" "startup"
    output_and_log "=== Systemd Enabled Services ===" "startup"
    output_and_log "UNIT\t\t\t\t\tLOAD\tACTIVE\tSUB\tDESCRIPTION" "startup" "INFO"
    output_and_log "----\t\t\t\t\t----\t------\t---\t-----------" "startup" "INFO"
    systemctl list-unit-files --type=service | grep enabled | while read line; do
        output_and_log "$line" "startup" "INFO"
    done
    echo ""
    
    # Check for suspicious systemd services
    print_command_info "Suspicious Systemd Services Check" "systemctl list-unit-files --type=service | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu'" "startup"
    output_and_log "=== Suspicious Systemd Services ===" "startup"
    local suspicious_services=$(systemctl list-unit-files --type=service | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu')
    if [[ -n "$suspicious_services" ]]; then
        output_and_log "CRITICAL: Suspicious systemd services found:" "startup" "CRITICAL"
        echo "$suspicious_services" | while read line; do
            output_and_log "  - $line" "startup" "CRITICAL"
        done
    else
        output_and_log "No suspicious systemd services found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check systemd service files
    print_command_info "Systemd Service Files Check" "ls -la /etc/systemd/system/" "startup"
    output_and_log "=== Systemd Service Files ===" "startup"
    ls -la /etc/systemd/system/ | while read line; do
        output_and_log "$line" "startup" "INFO"
    done
    echo ""
    
    # Check multi-user target wants
    print_command_info "Multi-user Target Wants Check" "ls -la /etc/systemd/system/multi-user.target.wants/" "startup"
    output_and_log "=== Multi-user Target Wants ===" "startup"
    if [[ -d /etc/systemd/system/multi-user.target.wants ]]; then
        ls -la /etc/systemd/system/multi-user.target.wants/ | while read line; do
            output_and_log "$line" "startup" "INFO"
        done
    else
        output_and_log "Multi-user target wants directory not found" "startup" "WARNING"
    fi
    echo ""
    
    # Check rc.local file
    print_command_info "RC Local Check" "cat /etc/rc.d/rc.local" "startup"
    output_and_log "=== RC Local File ===" "startup"
    if [[ -f /etc/rc.d/rc.local ]]; then
        if [[ -s /etc/rc.d/rc.local ]]; then
            output_and_log "WARNING: RC local file contains commands:" "startup" "WARNING"
            cat /etc/rc.d/rc.local | while read line; do
                output_and_log "  $line" "startup" "WARNING"
            done
        else
            output_and_log "RC local file is empty" "startup" "SUCCESS"
        fi
    else
        output_and_log "RC local file not found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check for startup scripts in /etc/init.d
    print_command_info "Init.d Scripts Check" "ls -la /etc/init.d/" "startup"
    output_and_log "=== Init.d Scripts ===" "startup"
    ls -la /etc/init.d/ | while read line; do
        output_and_log "$line" "startup" "INFO"
    done
    echo ""
    
    # Check for suspicious init.d scripts
    print_command_info "Suspicious Init.d Scripts Check" "ls /etc/init.d/ | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu'" "startup"
    output_and_log "=== Suspicious Init.d Scripts ===" "startup"
    local suspicious_init_scripts=$(ls /etc/init.d/ | grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' 2>/dev/null)
    if [[ -n "$suspicious_init_scripts" ]]; then
        output_and_log "CRITICAL: Suspicious init.d scripts found:" "startup" "CRITICAL"
        echo "$suspicious_init_scripts" | while read script; do
            output_and_log "  - $script" "startup" "CRITICAL"
        done
    else
        output_and_log "No suspicious init.d scripts found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check for startup scripts in user directories
    print_command_info "User Startup Scripts Check" "find /home -name '.*rc' -o -name '.*profile' -type f" "startup"
    output_and_log "=== User Startup Scripts ===" "startup"
    find /home -name ".*rc" -o -name ".*profile" -type f 2>/dev/null | while read script; do
        output_and_log "User startup script: $script" "startup" "INFO"
        if [[ -s "$script" ]]; then
            output_and_log "Content:" "startup" "INFO"
            cat "$script" | while read line; do
                output_and_log "  $line" "startup" "INFO"
            done
        fi
        echo ""
    done
    
    # Check for startup scripts in root directory
    print_command_info "Root Startup Scripts Check" "find /root -name '.*rc' -o -name '.*profile' -type f" "startup"
    output_and_log "=== Root Startup Scripts ===" "startup"
    find /root -name ".*rc" -o -name ".*profile" -type f 2>/dev/null | while read script; do
        output_and_log "Root startup script: $script" "startup" "INFO"
        if [[ -s "$script" ]]; then
            output_and_log "Content:" "startup" "INFO"
            cat "$script" | while read line; do
                output_and_log "  $line" "startup" "INFO"
            done
        fi
        echo ""
    done
    
    # Check for startup applications
    print_command_info "Startup Applications Check" "ls -la /etc/xdg/autostart/" "startup"
    output_and_log "=== Startup Applications ===" "startup"
    if [[ -d /etc/xdg/autostart ]]; then
        ls -la /etc/xdg/autostart/ | while read line; do
            output_and_log "$line" "startup" "INFO"
        done
    else
        output_and_log "No startup applications directory found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check for systemd user services
    print_command_info "Systemd User Services Check" "systemctl --user list-unit-files --type=service | grep enabled" "startup"
    output_and_log "=== Systemd User Services ===" "startup"
    systemctl --user list-unit-files --type=service | grep enabled 2>/dev/null | while read line; do
        output_and_log "$line" "startup" "INFO"
    done
    echo ""
    
    # Check for recently modified startup files
    print_command_info "Recently Modified Startup Files Check" "find /etc/systemd/system /etc/init.d /etc/rc.d -mtime -7 -type f" "startup"
    output_and_log "=== Recently Modified Startup Files (Last 7 Days) ===" "startup"
    local recent_startup_files=$(find /etc/systemd/system /etc/init.d /etc/rc.d -mtime -7 -type f 2>/dev/null)
    if [[ -n "$recent_startup_files" ]]; then
        output_and_log "WARNING: Recently modified startup files found:" "startup" "WARNING"
        echo "$recent_startup_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "startup" "WARNING"
        done
    else
        output_and_log "No recently modified startup files found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check for startup scripts with unusual permissions
    print_command_info "Unusual Startup Script Permissions Check" "find /etc/init.d /etc/systemd/system -perm -o+w -type f" "startup"
    output_and_log "=== Startup Scripts with Unusual Permissions ===" "startup"
    local unusual_perms=$(find /etc/init.d /etc/systemd/system -perm -o+w -type f 2>/dev/null)
    if [[ -n "$unusual_perms" ]]; then
        output_and_log "CRITICAL: Startup scripts with unusual permissions found:" "startup" "CRITICAL"
        echo "$unusual_perms" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "startup" "CRITICAL"
        done
    else
        output_and_log "No startup scripts with unusual permissions found" "startup" "SUCCESS"
    fi
    echo ""
    
    # Check for startup scripts with suspicious content
    print_command_info "Suspicious Startup Script Content Check" "grep -r -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' /etc/init.d/ /etc/systemd/system/" "startup"
    output_and_log "=== Startup Scripts with Suspicious Content ===" "startup"
    local suspicious_content=$(grep -r -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' /etc/init.d/ /etc/systemd/system/ 2>/dev/null)
    if [[ -n "$suspicious_content" ]]; then
        output_and_log "CRITICAL: Startup scripts with suspicious content found:" "startup" "CRITICAL"
        echo "$suspicious_content" | while read line; do
            output_and_log "  - $line" "startup" "CRITICAL"
        done
    else
        output_and_log "No startup scripts with suspicious content found" "startup" "SUCCESS"
    fi
    echo ""
    
    log_message "INFO" "Startup investigation module completed" "startup"
}

# Execute startup investigation
startup_investigation 