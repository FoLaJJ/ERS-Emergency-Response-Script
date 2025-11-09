#!/bin/sh
# Startup Investigation Module
# Checks autostart tasks, systemd services, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_startup() {
    local log_file="$LOG_STARTUP"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_STARTUP is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Startup Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Startup Investigation Module"
    
    # Check systemd services
    if should_investigate "minimal"; then
        if bb which systemctl >/dev/null 2>&1; then
            execute_and_log "Check enabled systemd services" \
                "systemctl list-unit-files --type=service --state=enabled 2>/dev/null | bb head -100" \
                "$log_file" "minimal"
        fi
    fi
    
    # Check all systemd unit files
    if should_investigate "normal"; then
        if bb which systemctl >/dev/null 2>&1; then
            execute_and_log "Check all systemd unit files" \
                "systemctl list-unit-files --type=service 2>/dev/null | bb head -100" \
                "$log_file" "normal"
        fi
    fi
    
    # Check systemd system directory
    if should_investigate "normal"; then
        if [ -d /etc/systemd/system ]; then
            execute_and_log "Check /etc/systemd/system directory" \
                "bb ls -la /etc/systemd/system/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check systemd multi-user target wants
    if should_investigate "normal"; then
        if [ -d /etc/systemd/system/multi-user.target.wants ]; then
            execute_and_log "Check multi-user.target.wants directory" \
                "bb ls -la /etc/systemd/system/multi-user.target.wants/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check rc.local
    if should_investigate "normal"; then
        if [ -f /etc/rc.local ]; then
            execute_and_log "Check /etc/rc.local" \
                "bb cat /etc/rc.local" \
                "$log_file" "normal"
        elif [ -f /etc/rc.d/rc.local ]; then
            execute_and_log "Check /etc/rc.d/rc.local" \
                "bb cat /etc/rc.d/rc.local" \
                "$log_file" "normal"
        fi
    fi
    
    # Check user startup scripts
    if should_investigate "normal"; then
        execute_and_log "Check user .bashrc startup scripts" \
            "bb find /home /root -name .bashrc -exec bb sh -c 'echo \"=== {} ===\"; bb tail -20 {}' \; 2>/dev/null" \
            "$log_file" "normal"
        
        execute_and_log "Check user .bash_profile startup scripts" \
            "bb find /home /root -name .bash_profile -exec bb sh -c 'echo \"=== {} ===\"; bb cat {}' \; 2>/dev/null" \
            "$log_file" "normal"
        
        execute_and_log "Check user .profile startup scripts" \
            "bb find /home /root -name .profile -exec bb sh -c 'echo \"=== {} ===\"; bb cat {}' \; 2>/dev/null" \
            "$log_file" "normal"
    fi
    
    # Check autostart directories
    if should_investigate "normal"; then
        local autostart_dirs="/etc/xdg/autostart /home/*/.config/autostart /root/.config/autostart"
        for dir in $autostart_dirs; do
            if [ -d "$dir" ]; then
                execute_and_log "Check autostart directory: $dir" \
                    "bb ls -la $dir 2>/dev/null" \
                    "$log_file" "normal"
            fi
        done
    fi
    
    # Check init.d scripts
    if should_investigate "normal"; then
        if [ -d /etc/init.d ]; then
            execute_and_log "Check /etc/init.d scripts" \
                "bb ls -la /etc/init.d/ 2>/dev/null | bb head -50" \
                "$log_file" "normal"
        fi
    fi
    
    # Check systemd timers
    if should_investigate "detailed"; then
        if bb which systemctl >/dev/null 2>&1; then
            execute_and_log "Check systemd timers" \
                "systemctl list-timers --all 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check for suspicious systemd services
    if should_investigate "detailed"; then
        if [ -d /etc/systemd/system ]; then
            execute_and_log "Check for suspicious systemd service files" \
                "bb find /etc/systemd/system -name '*.service' -exec bb sh -c 'echo \"=== {} ===\"; bb cat {}' \; 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check /etc/init directory (upstart)
    if should_investigate "detailed"; then
        if [ -d /etc/init ]; then
            execute_and_log "Check /etc/init directory (upstart)" \
                "bb ls -la /etc/init/ 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Summary
    print_section "Startup Investigation Summary"
    local service_count=0
    if bb which systemctl >/dev/null 2>&1; then
        service_count=$(systemctl list-unit-files --type=service --state=enabled 2>/dev/null | bb wc -l)
    fi
    
    echo "Enabled systemd services: $service_count"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Enabled services: $service_count"
    
    print_success "Startup investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "startup_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_startup
fi

