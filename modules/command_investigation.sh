#!/bin/sh
# Command Investigation Module
# Checks if commands are tampered, aliases, PATH, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_commands() {
    local log_file="$LOG_COMMAND"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_COMMAND is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Command Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Command Investigation Module"
    
    # Check aliases
    if should_investigate "minimal"; then
        execute_and_log "Check current aliases" \
            "alias 2>/dev/null || echo 'No aliases found'" \
            "$log_file" "minimal"
    fi
    
    # Check PATH environment variable
    if should_investigate "minimal"; then
        execute_and_log "Check PATH environment variable" \
            "echo \"\$PATH\" | bb tr ':' '\n' | bb nl" \
            "$log_file" "minimal"
        
        local suspicious_paths=$(echo "$PATH" | bb tr ':' '\n' | bb grep -E '^(/tmp|/var/tmp|\.)')
        if [ -n "$suspicious_paths" ]; then
            print_error "Suspicious paths in PATH: $suspicious_paths"
            log_to_file "$log_file" "ERROR: Suspicious paths in PATH: $suspicious_paths"
        fi
    fi
    
    # Check shell configuration files
    if should_investigate "normal"; then
        execute_and_log "Check .bashrc files" \
            "bb find /home /root -name .bashrc -type f -exec bb ls -lctr {} \; 2>/dev/null" \
            "$log_file" "normal"
        
        execute_and_log "Check .bash_profile files" \
            "bb find /home /root -name .bash_profile -type f -exec bb ls -lctr {} \; 2>/dev/null" \
            "$log_file" "normal"
        
        execute_and_log "Check .profile files" \
            "bb find /home /root -name .profile -type f -exec bb ls -lctr {} \; 2>/dev/null" \
            "$log_file" "normal"
    fi
    
    # Check system-wide shell configuration
    if should_investigate "normal"; then
        if [ -f /etc/bash.bashrc ]; then
            execute_and_log "Check /etc/bash.bashrc" \
                "bb cat /etc/bash.bashrc | bb grep -v '^#' | bb grep -v '^$' | bb head -50" \
                "$log_file" "normal"
        fi
        
        if [ -f /etc/profile ]; then
            execute_and_log "Check /etc/profile" \
                "bb cat /etc/profile | bb grep -v '^#' | bb grep -v '^$' | bb head -50" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for suspicious commands in common locations
    if should_investigate "detailed"; then
        execute_and_log "Check for suspicious binaries in /tmp and /var/tmp" \
            "bb find /tmp /var/tmp -type f -executable 2>/dev/null | bb head -20" \
            "$log_file" "detailed"
    fi
    
    # Check which/whereis for common commands
    if should_investigate "normal"; then
        local commands="ls ps netstat ss top kill"
        for cmd in $commands; do
            execute_and_log "Check location of $cmd command" \
                "bb which $cmd 2>/dev/null || echo 'Command not found in PATH'" \
                "$log_file" "normal"
        done
    fi
    
    # Check file permissions of common binaries
    if should_investigate "detailed"; then
        local bin_paths="/bin /usr/bin /usr/local/bin /sbin /usr/sbin"
        for bin_path in $bin_paths; do
            if [ -d "$bin_path" ]; then
                execute_and_log "Check suspicious permissions in $bin_path" \
                    "bb find $bin_path -type f -perm -002 -exec bb ls -l {} \; 2>/dev/null | bb head -10" \
                    "$log_file" "detailed"
            fi
        done
    fi
    
    # Check for setuid/setgid binaries
    if should_investigate "normal"; then
        execute_and_log "Check for setuid binaries" \
            "bb find /usr/bin /usr/sbin /bin /sbin -type f -perm -4000 2>/dev/null | bb head -30" \
            "$log_file" "normal"
        
        execute_and_log "Check for setgid binaries" \
            "bb find /usr/bin /usr/sbin /bin /sbin -type f -perm -2000 2>/dev/null | bb head -30" \
            "$log_file" "normal"
    fi
    
    # Check LD_PRELOAD and LD_LIBRARY_PATH
    if should_investigate "normal"; then
        execute_and_log "Check LD_PRELOAD environment variable" \
            "echo \"LD_PRELOAD=\$LD_PRELOAD\"" \
            "$log_file" "normal"
        
        execute_and_log "Check LD_LIBRARY_PATH environment variable" \
            "echo \"LD_LIBRARY_PATH=\$LD_LIBRARY_PATH\"" \
            "$log_file" "normal"
        
        if [ -n "$LD_PRELOAD" ]; then
            print_error "LD_PRELOAD is set: $LD_PRELOAD"
            log_to_file "$log_file" "ERROR: LD_PRELOAD is set: $LD_PRELOAD"
        fi
    fi
    
    # Check /etc/ld.so.preload
    if should_investigate "normal"; then
        if [ -f /etc/ld.so.preload ]; then
            execute_and_log "Check /etc/ld.so.preload (preloaded libraries)" \
                "bb cat /etc/ld.so.preload" \
                "$log_file" "normal"
            print_warning "/etc/ld.so.preload exists - could indicate library hijacking"
        fi
    fi
    
    # Recommendation to use busybox
    print_section "Command Investigation Summary"
    print_info "Recommendation: Use busybox for trusted command execution"
    print_info "Busybox location: $BUSYBOX"
    print_info "Example: $BUSYBOX ls -la"
    echo ""
    
    log_to_file "$log_file" "INFO: Recommendation to use busybox for trusted commands"
    
    print_success "Command investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "command_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_commands
fi

