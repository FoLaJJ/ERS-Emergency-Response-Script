#!/bin/bash

# User Investigation Module
# Checks for suspicious users, shadow users, SSH keys, and privilege escalation

user_investigation() {
    print_section "USER INVESTIGATION"
    
    log_message "INFO" "Starting user investigation module" "user"
    
    # Check all users in /etc/passwd
    print_command_info "User Information Check" "cat /etc/passwd" "user"
    output_and_log "=== All Users in /etc/passwd ===" "user"
    cat /etc/passwd | while IFS=: read -r username password uid gid info home shell; do
        output_and_log "User: $username UID: $uid Shell: $shell" "user" "INFO"
    done
    echo ""
    
    # Check users with login shells (excluding nologin and false)
    print_command_info "Login Users Check" "cat /etc/passwd | grep -v 'nologin\|false'" "user"
    output_and_log "=== Users with Login Shells ===" "user"
    cat /etc/passwd | grep -v 'nologin\|false' | while IFS=: read -r username password uid gid info home shell; do
        output_and_log "Login User: $username UID: $uid Shell: $shell" "user" "WARNING"
    done
    echo ""
    
    # Check for users with UID 0 (root privileges)
    print_command_info "Root Privilege Users Check" "cat /etc/passwd | awk -F: '\$3==0 {print \$1}'" "user"
    output_and_log "=== Users with UID 0 (Root Privileges) ===" "user"
    local root_users=$(cat /etc/passwd | awk -F: '$3==0 {print $1}')
    if [[ -n "$root_users" ]]; then
        output_and_log "CRITICAL: Users with root privileges found:" "user" "CRITICAL"
        echo "$root_users" | while read user; do
            output_and_log "  - $user" "user" "CRITICAL"
        done
        echo "$root_users" > "$TEMP_DIR/suspicious_users.txt"
    else
        output_and_log "No additional users with root privileges found" "user" "SUCCESS"
    fi
    echo ""
    
    # Check for recent user creation
    print_command_info "Recent User Creation Check" "ls -l /home" "user"
    output_and_log "=== Recent User Home Directories ===" "user"
    ls -l /home 2>/dev/null | while read line; do
        output_and_log "$line" "user" "INFO"
    done
    echo ""
    
    # Check SSH authorized keys
    print_command_info "SSH Authorized Keys Check" "find /home -name authorized_keys -type f" "user"
    output_and_log "=== SSH Authorized Keys Found ===" "user"
    find /home -name "authorized_keys" -type f 2>/dev/null | while read keyfile; do
        local owner=$(stat -c '%U' "$keyfile" 2>/dev/null)
        output_and_log "SSH Key File: $keyfile Owner: $owner" "user" "WARNING"
        if [[ -s "$keyfile" ]]; then
            output_and_log "Content:" "user" "INFO"
            cat "$keyfile" | while read line; do
                output_and_log "  $line" "user" "INFO"
            done
        fi
        echo ""
    done
    
    # Check root SSH keys
    if [[ -f /root/.ssh/authorized_keys ]]; then
        print_command_info "Root SSH Keys Check" "cat /root/.ssh/authorized_keys" "user"
        output_and_log "=== Root SSH Authorized Keys ===" "user"
        if [[ -s /root/.ssh/authorized_keys ]]; then
            output_and_log "CRITICAL: Root SSH keys found:" "user" "CRITICAL"
            cat /root/.ssh/authorized_keys | while read line; do
                output_and_log "  $line" "user" "CRITICAL"
            done
        else
            output_and_log "Root SSH authorized_keys file is empty" "user" "SUCCESS"
        fi
        echo ""
    fi
    
    # Check for users with empty passwords
    print_command_info "Empty Password Users Check" "cat /etc/shadow | awk -F: '\$2==\"\" {print \$1}'" "user"
    output_and_log "=== Users with Empty Passwords ===" "user"
    local empty_pass_users=$(cat /etc/shadow | awk -F: '$2=="" {print $1}' 2>/dev/null)
    if [[ -n "$empty_pass_users" ]]; then
        output_and_log "CRITICAL: Users with empty passwords found:" "user" "CRITICAL"
        echo "$empty_pass_users" | while read user; do
            output_and_log "  - $user" "user" "CRITICAL"
        done
        echo "$empty_pass_users" >> "$TEMP_DIR/suspicious_users.txt"
    else
        output_and_log "No users with empty passwords found" "user" "SUCCESS"
    fi
    echo ""
    
    # Check for users with weak password hashes
    print_command_info "Weak Password Hash Check" "cat /etc/shadow | grep -E '^\w+:\$1\$'" "user"
    output_and_log "=== Users with Weak Password Hashes (MD5) ===" "user"
    local weak_hash_users=$(cat /etc/shadow | grep -E '^\w+:\$1\$' | cut -d: -f1 2>/dev/null)
    if [[ -n "$weak_hash_users" ]]; then
        output_and_log "WARNING: Users with weak password hashes found:" "user" "WARNING"
        echo "$weak_hash_users" | while read user; do
            output_and_log "  - $user" "user" "WARNING"
        done
    else
        output_and_log "No users with weak password hashes found" "user" "SUCCESS"
    fi
    echo ""
    
    # Check for hidden users (users with UID > 1000 but no home directory)
    print_command_info "Hidden Users Check" "cat /etc/passwd | awk -F: '\$3 > 1000 && \$6 == \"/\" {print \$1}'" "user"
    output_and_log "=== Hidden Users (UID > 1000, no home directory) ===" "user"
    local hidden_users=$(cat /etc/passwd | awk -F: '$3 > 1000 && $6 == "/" {print $1}')
    if [[ -n "$hidden_users" ]]; then
        output_and_log "WARNING: Hidden users found:" "user" "WARNING"
        echo "$hidden_users" | while read user; do
            output_and_log "  - $user" "user" "WARNING"
        done
    else
        output_and_log "No hidden users found" "user" "SUCCESS"
    fi
    echo ""
    
    # Check for users with unusual shells
    print_command_info "Unusual Shells Check" "cat /etc/passwd | grep -v '/bin/bash\|/bin/sh\|/usr/sbin/nologin\|/bin/false'" "user"
    output_and_log "=== Users with Unusual Shells ===" "user"
    local unusual_shell_users=$(cat /etc/passwd | grep -v '/bin/bash\|/bin/sh\|/usr/sbin/nologin\|/bin/false' | cut -d: -f1,7)
    if [[ -n "$unusual_shell_users" ]]; then
        output_and_log "WARNING: Users with unusual shells found:" "user" "WARNING"
        echo "$unusual_shell_users" | while IFS=: read -r user shell; do
            output_and_log "  - $user: $shell" "user" "WARNING"
        done
    else
        output_and_log "No users with unusual shells found" "user" "SUCCESS"
    fi
    echo ""
    
    log_message "INFO" "User investigation module completed" "user"
}

# Execute user investigation
user_investigation 