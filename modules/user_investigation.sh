#!/bin/sh
# User Investigation Module
# Checks user information, shadow users, SSH keys, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_users() {
    local log_file="$LOG_USER"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_USER is not set. Cannot create log file."
        print_error "Please ensure set_log_paths() was called before running this module."
        print_error "DEBUG: LOG_USER='$LOG_USER', RESULTS_DIR='$RESULTS_DIR'"
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "User Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "User Investigation Module"
    
    # Check /etc/passwd
    if should_investigate "minimal"; then
        execute_and_log "Check all users in /etc/passwd" \
            "bb cat /etc/passwd" \
            "$log_file" "minimal"
    fi
    
    # Check users with login shells (excluding nologin and false)
    if should_investigate "normal"; then
        execute_and_log "Check users with login shells" \
            "bb cat /etc/passwd | bb grep -v 'nologin\|false'" \
            "$log_file" "normal"
    fi
    
    # Check users with UID 0 (root users)
    if should_investigate "minimal"; then
        execute_and_log "Check users with UID 0 (root privileges)" \
            "bb cat /etc/passwd | bb awk -F: '\$3==0 {print \$1}'" \
            "$log_file" "minimal"
        
        local root_users=$(bb cat /etc/passwd | bb awk -F: '$3==0 {print $1}')
        if [ -n "$root_users" ]; then
            print_warning "Found users with UID 0: $root_users"
            log_to_file "$log_file" "WARNING: Users with UID 0 found: $root_users"
        fi
    fi
    
    # Check /etc/shadow (if accessible)
    if should_investigate "normal"; then
        if [ -r /etc/shadow ]; then
            execute_and_log "Check shadow file (password hashes)" \
                "bb cat /etc/shadow" \
                "$log_file" "normal"
        else
            print_warning "Cannot read /etc/shadow (requires root privileges)"
            log_to_file "$log_file" "WARNING: Cannot read /etc/shadow"
        fi
    fi
    
    # Check recently created users
    if should_investigate "detailed"; then
        execute_and_log "Check recently modified users (last 30 days)" \
            "bb find /home -type d -mtime -30 -exec bb ls -ld {} \; 2>/dev/null | bb head -20" \
            "$log_file" "detailed"
    fi
    
    # Check SSH authorized_keys for root
    if should_investigate "minimal"; then
        if [ -f /root/.ssh/authorized_keys ]; then
            execute_and_log "Check root SSH authorized_keys" \
                "bb cat /root/.ssh/authorized_keys" \
                "$log_file" "minimal"
            print_warning "SSH keys found in /root/.ssh/authorized_keys"
        else
            print_info "No authorized_keys found in /root/.ssh/"
            log_to_file "$log_file" "INFO: No authorized_keys in /root/.ssh/"
        fi
    fi
    
    # Check SSH authorized_keys for all users
    if should_investigate "normal"; then
        execute_and_log "Check SSH authorized_keys for all users" \
            "bb find /home -name authorized_keys -type f 2>/dev/null -exec bb sh -c 'echo \"User: \$(dirname {} | bb xargs dirname | bb xargs basename)\"; bb cat {}; echo \"---\"' \;" \
            "$log_file" "normal"
    fi
    
    # Check users with no password (empty password field in shadow)
    if should_investigate "normal"; then
        if [ -r /etc/shadow ]; then
            execute_and_log "Check users with empty passwords" \
                "bb awk -F: '\$2==\"\" {print \$1}' /etc/shadow" \
                "$log_file" "normal"
            
            local empty_pass=$(bb awk -F: '$2=="" {print $1}' /etc/shadow 2>/dev/null)
            if [ -n "$empty_pass" ]; then
                print_error "Users with empty passwords found: $empty_pass"
                log_to_file "$log_file" "ERROR: Users with empty passwords: $empty_pass"
            fi
        fi
    fi
    
    # Check users with suspicious UIDs (system UIDs used by regular users)
    if should_investigate "detailed"; then
        execute_and_log "Check users with suspicious UIDs (1-999 range)" \
            "bb awk -F: '\$3 >= 1 && \$3 <= 999 && \$3 != 0 {print \$1 \":\" \$3}' /etc/passwd" \
            "$log_file" "detailed"
    fi
    
    # Check for duplicate UIDs
    if should_investigate "normal"; then
        execute_and_log "Check for duplicate UIDs" \
            "bb awk -F: '{print \$3}' /etc/passwd | bb sort -n | bb uniq -d" \
            "$log_file" "normal"
        
        local dup_uids=$(bb awk -F: '{print $3}' /etc/passwd | bb sort -n | bb uniq -d)
        if [ -n "$dup_uids" ]; then
            print_error "Duplicate UIDs found: $dup_uids"
            log_to_file "$log_file" "ERROR: Duplicate UIDs: $dup_uids"
        fi
    fi
    
    # Check sudoers file
    if should_investigate "normal"; then
        if [ -f /etc/sudoers ]; then
            execute_and_log "Check sudoers configuration" \
                "bb cat /etc/sudoers 2>/dev/null | bb grep -v '^#' | bb grep -v '^$'" \
                "$log_file" "normal"
        fi
    fi
    
    # Summary table
    print_section "User Investigation Summary"
    local user_count=$(bb cat /etc/passwd | bb wc -l)
    local login_users=$(bb cat /etc/passwd | bb grep -v 'nologin\|false' | bb wc -l)
    local root_count=$(bb cat /etc/passwd | bb awk -F: '$3==0 {print $1}' | bb wc -l)
    
    echo "Total Users: $user_count"
    echo "Users with Login Shells: $login_users"
    echo "Users with UID 0: $root_count"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Total users: $user_count, Login users: $login_users, Root users: $root_count"
    
    print_success "User investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "user_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_users
fi

