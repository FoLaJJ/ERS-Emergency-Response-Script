#!/bin/bash

# Command Investigation Module
# Checks for command tampering, aliases, and ensures command integrity

command_investigation() {
    print_section "COMMAND INVESTIGATION"
    
    log_message "INFO" "Starting command investigation module" "command"
    
    # Check current aliases
    print_command_info "Alias Check" "alias" "command"
    output_and_log "=== Current Aliases ===" "command"
    alias | while read line; do
        output_and_log "$line" "command" "INFO"
    done
    echo ""
    
    # Check for suspicious aliases
    print_command_info "Suspicious Alias Check" "alias | grep -i 'ls\|ps\|netstat\|wget\|curl'" "command"
    output_and_log "=== Suspicious Aliases Found ===" "command"
    local suspicious_aliases=$(alias | grep -i 'ls\|ps\|netstat\|wget\|curl' 2>/dev/null)
    if [[ -n "$suspicious_aliases" ]]; then
        output_and_log "CRITICAL: Suspicious aliases found:" "command" "CRITICAL"
        echo "$suspicious_aliases" | while read alias_line; do
            output_and_log "  - $alias_line" "command" "CRITICAL"
        done
    else
        output_and_log "No suspicious aliases found" "command" "SUCCESS"
    fi
    echo ""
    
    # Check for command tampering in common directories
    print_command_info "Command Tampering Check" "find /usr/bin /usr/sbin /bin /sbin -name 'ls' -o -name 'ps' -o -name 'netstat' -o -name 'wget' -o -name 'curl'" "command"
    output_and_log "=== Critical Commands Integrity Check ===" "command"
    local critical_commands=("ls" "ps" "netstat" "wget" "curl" "ssh" "scp" "nc" "ncat")
    
    for cmd in "${critical_commands[@]}"; do
        local cmd_path=$(which "$cmd" 2>/dev/null)
        if [[ -n "$cmd_path" ]]; then
            local file_info=$(ls -la "$cmd_path" 2>/dev/null)
            local file_hash=$(md5sum "$cmd_path" 2>/dev/null | cut -d' ' -f1)
            output_and_log "Command: $cmd" "command" "INFO"
            output_and_log "Path: $cmd_path" "command" "INFO"
            output_and_log "File Info: $file_info" "command" "INFO"
            output_and_log "MD5 Hash: $file_hash" "command" "INFO"
            echo ""
        fi
    done
    
    # Check for hidden files in common directories
    print_command_info "Hidden Files Check" "find /usr/bin /usr/sbin /bin /sbin -name '.*' -type f" "command"
    output_and_log "=== Hidden Files in System Directories ===" "command"
    local hidden_files=$(find /usr/bin /usr/sbin /bin /sbin -name '.*' -type f 2>/dev/null)
    if [[ -n "$hidden_files" ]]; then
        output_and_log "WARNING: Hidden files found in system directories:" "command" "WARNING"
        echo "$hidden_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "command" "WARNING"
        done
    else
        output_and_log "No hidden files found in system directories" "command" "SUCCESS"
    fi
    echo ""
    
    # Check for modified files in last 7 days
    print_command_info "Recently Modified Files Check" "find /usr/bin /usr/sbin /bin /sbin -mtime -7 -type f" "command"
    output_and_log "=== Recently Modified System Files (Last 7 Days) ===" "command"
    local recent_files=$(find /usr/bin /usr/sbin /bin /sbin -mtime -7 -type f 2>/dev/null)
    if [[ -n "$recent_files" ]]; then
        output_and_log "WARNING: Recently modified system files found:" "command" "WARNING"
        echo "$recent_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "command" "WARNING"
        done
    else
        output_and_log "No recently modified system files found" "command" "SUCCESS"
    fi
    echo ""
    
    # Check for busybox installation
    print_command_info "Busybox Check" "which busybox" "command"
    output_and_log "=== Busybox Availability Check ===" "command"
    if command -v busybox >/dev/null 2>&1; then
        output_and_log "Busybox is available" "command" "SUCCESS"
        output_and_log "Busybox version:" "command" "INFO"
        busybox --help | head -5 | while read line; do
            output_and_log "$line" "command" "INFO"
        done
    else
        output_and_log "Busybox not found. Installing for command integrity..." "command" "WARNING"
        apt update && apt install -y busybox-static
        if command -v busybox >/dev/null 2>&1; then
            output_and_log "Busybox installed successfully" "command" "SUCCESS"
        else
            output_and_log "Failed to install busybox" "command" "ERROR"
        fi
    fi
    echo ""
    
    # Check PATH environment variable
    print_command_info "PATH Environment Check" "echo \$PATH" "command"
    output_and_log "=== PATH Environment Variable ===" "command"
    output_and_log "Current PATH: $PATH" "command" "INFO"
    echo ""
    
    # Check for writable directories in PATH
    print_command_info "Writable PATH Directories Check" "echo \$PATH | tr ':' '\n' | xargs -I {} sh -c 'test -w {} && echo {}'" "command"
    output_and_log "=== Writable Directories in PATH ===" "command"
    echo "$PATH" | tr ':' '\n' | while read dir; do
        if [[ -w "$dir" ]]; then
            output_and_log "CRITICAL: Writable directory in PATH: $dir" "command" "CRITICAL"
        fi
    done
    echo ""
    
    # Check for command substitution in shell configuration files
    print_command_info "Shell Configuration Check" "find /home /root -name '.*rc' -o -name '.*profile' -type f" "command"
    output_and_log "=== Shell Configuration Files ===" "command"
    find /home /root -name ".*rc" -o -name ".*profile" -type f 2>/dev/null | while read config_file; do
        output_and_log "Config File: $config_file" "command" "INFO"
        if [[ -s "$config_file" ]]; then
            output_and_log "Content:" "command" "INFO"
            cat "$config_file" | while read line; do
                output_and_log "  $line" "command" "INFO"
            done
        fi
        echo ""
    done
    
    # Check for command history
    print_command_info "Command History Check" "history" "command"
    output_and_log "=== Recent Command History ===" "command"
    if [[ -f ~/.bash_history ]]; then
        output_and_log "Recent commands from bash history:" "command" "INFO"
        tail -20 ~/.bash_history | while read cmd; do
            output_and_log "  $cmd" "command" "INFO"
        done
    fi
    echo ""
    
    log_message "INFO" "Command investigation module completed" "command"
}

# Execute command investigation
command_investigation 