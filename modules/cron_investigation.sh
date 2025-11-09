#!/bin/sh
# Cron Investigation Module
# Checks cron jobs, at jobs, anacron, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_cron() {
    local log_file="$LOG_CRON"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_CRON is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Cron Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Cron Investigation Module"
    
    # Check system crontab
    if should_investigate "minimal"; then
        if [ -f /etc/crontab ]; then
            execute_and_log "Check /etc/crontab" \
                "bb cat /etc/crontab" \
                "$log_file" "minimal"
        fi
    fi
    
    # Check cron.d directory
    if should_investigate "minimal"; then
        if [ -d /etc/cron.d ]; then
            execute_and_log "Check /etc/cron.d directory" \
                "bb ls -la /etc/cron.d/ 2>/dev/null" \
                "$log_file" "minimal"
            
            for file in /etc/cron.d/*; do
                if [ -f "$file" ]; then
                    execute_and_log "Check cron.d file: $file" \
                        "bb cat $file" \
                        "$log_file" "minimal"
                fi
            done
        fi
    fi
    
    # Check cron hourly
    if should_investigate "normal"; then
        if [ -d /etc/cron.hourly ]; then
            execute_and_log "Check /etc/cron.hourly directory" \
                "bb ls -la /etc/cron.hourly/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check cron daily
    if should_investigate "normal"; then
        if [ -d /etc/cron.daily ]; then
            execute_and_log "Check /etc/cron.daily directory" \
                "bb ls -la /etc/cron.daily/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check cron weekly
    if should_investigate "normal"; then
        if [ -d /etc/cron.weekly ]; then
            execute_and_log "Check /etc/cron.weekly directory" \
                "bb ls -la /etc/cron.weekly/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check cron monthly
    if should_investigate "normal"; then
        if [ -d /etc/cron.monthly ]; then
            execute_and_log "Check /etc/cron.monthly directory" \
                "bb ls -la /etc/cron.monthly/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check user crontabs
    if should_investigate "normal"; then
        if bb which crontab >/dev/null 2>&1; then
            execute_and_log "Check root crontab" \
                "crontab -l -u root 2>/dev/null || echo 'No root crontab or permission denied'" \
                "$log_file" "normal"
            
            # Check crontabs for all users with home directories
            for user in $(bb cat /etc/passwd | bb awk -F: '{print $1}'); do
                if [ -d "/home/$user" ] || [ "$user" = "root" ]; then
                    execute_and_log "Check crontab for user: $user" \
                        "crontab -l -u $user 2>/dev/null || echo 'No crontab for $user'" \
                        "$log_file" "normal"
                fi
            done
        fi
    fi
    
    # Check /var/spool/cron
    if should_investigate "normal"; then
        if [ -d /var/spool/cron ]; then
            execute_and_log "Check /var/spool/cron directory" \
                "bb ls -la /var/spool/cron/ 2>/dev/null" \
                "$log_file" "normal"
            
            for file in /var/spool/cron/*; do
                if [ -f "$file" ]; then
                    execute_and_log "Check crontab file: $file" \
                        "bb cat $file" \
                        "$log_file" "normal"
                fi
            done
        fi
    fi
    
    # Check /var/spool/cron/crontabs
    if should_investigate "normal"; then
        if [ -d /var/spool/cron/crontabs ]; then
            execute_and_log "Check /var/spool/cron/crontabs directory" \
                "bb ls -la /var/spool/cron/crontabs/ 2>/dev/null" \
                "$log_file" "normal"
        fi
    fi
    
    # Check at jobs
    if should_investigate "detailed"; then
        if [ -d /var/spool/at ]; then
            execute_and_log "Check at jobs directory" \
                "bb ls -la /var/spool/at/ 2>/dev/null" \
                "$log_file" "detailed"
        fi
        
        if bb which atq >/dev/null 2>&1; then
            execute_and_log "Check pending at jobs" \
                "atq 2>/dev/null || echo 'No at jobs or permission denied'" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check anacron
    if should_investigate "detailed"; then
        if [ -f /etc/anacrontab ]; then
            execute_and_log "Check /etc/anacrontab" \
                "bb cat /etc/anacrontab" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check for suspicious cron entries
    if should_investigate "detailed"; then
        local suspicious_patterns="wget curl bash sh /tmp /var/tmp"
        for pattern in $suspicious_patterns; do
            execute_and_log "Check for suspicious cron entries containing: $pattern" \
                "bb find /etc/cron* /var/spool/cron* -type f -exec bb grep -l $pattern {} \; 2>/dev/null || echo 'No matches found'" \
                "$log_file" "detailed"
        done
    fi
    
    # Summary
    print_section "Cron Investigation Summary"
    local cron_file_count=0
    if [ -d /etc/cron.d ]; then
        cron_file_count=$(bb ls /etc/cron.d/ 2>/dev/null | bb wc -l)
    fi
    
    echo "Cron configuration files in /etc/cron.d: $cron_file_count"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Cron files in /etc/cron.d: $cron_file_count"
    
    print_success "Cron investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "cron_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_cron
fi

