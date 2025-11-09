#!/bin/sh
# Log Investigation Module
# Checks logs, history, attack methods, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_logs() {
    local log_file="$LOG_LOG"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_LOG is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Log Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Log Investigation Module"
    
    # Check auth.log for SSH attempts
    if should_investigate "minimal"; then
        if [ -f /var/log/auth.log ]; then
            execute_and_log "Check recent SSH login attempts (auth.log)" \
                "bb tail -100 /var/log/auth.log 2>/dev/null | bb grep -i ssh" \
                "$log_file" "minimal"
        elif [ -f /var/log/secure ]; then
            execute_and_log "Check recent SSH login attempts (secure)" \
                "bb tail -100 /var/log/secure 2>/dev/null | bb grep -i ssh" \
                "$log_file" "minimal"
        fi
    fi
    
    # Check for failed login attempts
    if should_investigate "normal"; then
        if [ -f /var/log/auth.log ]; then
            execute_and_log "Check failed login attempts" \
                "bb grep -i 'failed\|invalid\|authentication failure' /var/log/auth.log 2>/dev/null | bb tail -50" \
                "$log_file" "normal"
        elif [ -f /var/log/secure ]; then
            execute_and_log "Check failed login attempts (secure)" \
                "bb grep -i 'failed\|invalid\|authentication failure' /var/log/secure 2>/dev/null | bb tail -50" \
                "$log_file" "normal"
        fi
    fi
    
    # Check bash history for all users
    if should_investigate "normal"; then
        execute_and_log "Check root bash history" \
            "bb tail -100 /root/.bash_history 2>/dev/null || echo 'No root bash history found'" \
            "$log_file" "normal"
        
        for user in $(bb cat /etc/passwd | bb awk -F: '{print $6}'); do
            if [ -f "$user/.bash_history" ]; then
                local username=$(bb basename "$user")
                execute_and_log "Check bash history for user: $username" \
                    "bb tail -50 $user/.bash_history 2>/dev/null" \
                    "$log_file" "normal"
            fi
        done
    fi
    
    # Check syslog
    if should_investigate "normal"; then
        if [ -f /var/log/syslog ]; then
            execute_and_log "Check recent syslog entries" \
                "bb tail -100 /var/log/syslog 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for suspicious commands in history
    if should_investigate "detailed"; then
        local suspicious_commands="wget curl bash sh chmod +x /tmp miner xmrig"
        for cmd in $suspicious_commands; do
            execute_and_log "Check for suspicious command in history: $cmd" \
                "bb find /root /home -name .bash_history -exec bb grep -l $cmd {} \; 2>/dev/null | bb head -10" \
                "$log_file" "detailed"
        done
    fi
    
    # Check kernel log
    if should_investigate "normal"; then
        if [ -f /var/log/kern.log ]; then
            execute_and_log "Check recent kernel log entries" \
                "bb tail -50 /var/log/kern.log 2>/dev/null" \
                "$log_file" "normal"
        elif [ -f /var/log/messages ]; then
            execute_and_log "Check recent messages log" \
                "bb tail -50 /var/log/messages 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check daemon log
    if should_investigate "detailed"; then
        if [ -f /var/log/daemon.log ]; then
            execute_and_log "Check recent daemon log entries" \
                "bb tail -50 /var/log/daemon.log 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check lastlog
    if should_investigate "normal"; then
        if [ -f /var/log/lastlog ]; then
            execute_and_log "Check last login records" \
                "lastlog 2>/dev/null | bb head -20 || echo 'Cannot read lastlog'" \
                "$log_file" "normal"
        fi
    fi
    
    # Check wtmp and utmp
    if should_investigate "normal"; then
        if [ -f /var/log/wtmp ]; then
            execute_and_log "Check recent logins (wtmp)" \
                "last -20 2>/dev/null || echo 'Cannot read wtmp'" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for web server logs
    if should_investigate "detailed"; then
        if [ -f /var/log/apache2/access.log ]; then
            execute_and_log "Check recent Apache access log entries" \
                "bb tail -50 /var/log/apache2/access.log 2>/dev/null" \
                "$log_file" "detailed"
        fi
        
        if [ -f /var/log/nginx/access.log ]; then
            execute_and_log "Check recent Nginx access log entries" \
                "bb tail -50 /var/log/nginx/access.log 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check for installation logs
    if should_investigate "detailed"; then
        if [ -f /var/log/dpkg.log ]; then
            execute_and_log "Check recent package installations" \
                "bb grep 'install\|remove' /var/log/dpkg.log 2>/dev/null | bb tail -50" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check for cron execution logs
    if should_investigate "detailed"; then
        if [ -f /var/log/cron ]; then
            execute_and_log "Check recent cron execution logs" \
                "bb tail -50 /var/log/cron 2>/dev/null" \
                "$log_file" "detailed"
        fi
    fi
    
    # Summary
    print_section "Log Investigation Summary"
    echo "Checked various system logs for suspicious activities"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Log investigation completed"
    
    print_success "Log investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "log_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_logs
fi

