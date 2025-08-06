#!/bin/bash

# System Investigation Module
# Checks for system information, file system, and other important system checks

system_investigation() {
    print_section "SYSTEM INVESTIGATION"
    
    log_message "INFO" "Starting system investigation module" "system"
    
    # Check system information
    print_command_info "System Information Check" "uname -a" "system"
    output_and_log "=== System Information ===" "system"
    uname -a | while read line; do
        output_and_log "$line" "system" "INFO"
    done
    echo ""
    
    # Check system uptime
    print_command_info "System Uptime Check" "uptime" "system"
    output_and_log "=== System Uptime ===" "system"
    uptime | while read line; do
        output_and_log "$line" "system" "INFO"
    done
    echo ""
    
    # Check system load
    print_command_info "System Load Check" "cat /proc/loadavg" "system"
    output_and_log "=== System Load Average ===" "system"
    cat /proc/loadavg | while read line; do
        output_and_log "$line" "system" "INFO"
    done
    echo ""
    
    # Check disk usage
    print_command_info "Disk Usage Check" "df -h" "system"
    output_and_log "=== Disk Usage ===" "system"
    df -h | while read line; do
        output_and_log "$line" "system" "INFO"
    done
    echo ""
    
    # Check for suspicious files in common directories
    print_command_info "Suspicious Files Check" "find /tmp /var/tmp /dev/shm -name '*miner*' -o -name '*xmr*' -o -name '*monero*' -o -name '*bitcoin*' -o -name '*eth*'" "system"
    output_and_log "=== Suspicious Files in Temporary Directories ===" "system"
    local suspicious_temp_files=$(find /tmp /var/tmp /dev/shm -name '*miner*' -o -name '*xmr*' -o -name '*monero*' -o -name '*bitcoin*' -o -name '*eth*' 2>/dev/null)
    if [[ -n "$suspicious_temp_files" ]]; then
        output_and_log "CRITICAL: Suspicious files in temporary directories found:" "system" "CRITICAL"
        echo "$suspicious_temp_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "CRITICAL"
        done
    else
        output_and_log "No suspicious files found in temporary directories" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for recently modified files
    print_command_info "Recently Modified Files Check" "find /tmp /var/tmp /dev/shm -mtime -1 -type f" "system"
    output_and_log "=== Recently Modified Files (Last 24 Hours) ===" "system"
    local recent_files=$(find /tmp /var/tmp /dev/shm -mtime -1 -type f 2>/dev/null)
    if [[ -n "$recent_files" ]]; then
        output_and_log "WARNING: Recently modified files found:" "system" "WARNING"
        echo "$recent_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No recently modified files found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for hidden files
    print_command_info "Hidden Files Check" "find /tmp /var/tmp /dev/shm -name '.*' -type f" "system"
    output_and_log "=== Hidden Files in Temporary Directories ===" "system"
    local hidden_files=$(find /tmp /var/tmp /dev/shm -name '.*' -type f 2>/dev/null)
    if [[ -n "$hidden_files" ]]; then
        output_and_log "WARNING: Hidden files found:" "system" "WARNING"
        echo "$hidden_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No hidden files found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual permissions
    print_command_info "Unusual File Permissions Check" "find /tmp /var/tmp /dev/shm -perm -o+x -type f" "system"
    output_and_log "=== Files with Unusual Permissions ===" "system"
    local unusual_perms=$(find /tmp /var/tmp /dev/shm -perm -o+x -type f 2>/dev/null)
    if [[ -n "$unusual_perms" ]]; then
        output_and_log "CRITICAL: Files with unusual permissions found:" "system" "CRITICAL"
        echo "$unusual_perms" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "CRITICAL"
        done
    else
        output_and_log "No files with unusual permissions found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with suspicious content
    print_command_info "Files with Suspicious Content Check" "find /tmp /var/tmp /dev/shm -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \;" "system"
    output_and_log "=== Files with Suspicious Content ===" "system"
    local suspicious_content_files=$(find /tmp /var/tmp /dev/shm -type f -exec grep -l -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' {} \; 2>/dev/null)
    if [[ -n "$suspicious_content_files" ]]; then
        output_and_log "CRITICAL: Files with suspicious content found:" "system" "CRITICAL"
        echo "$suspicious_content_files" | while read file; do
            output_and_log "  - $file" "system" "CRITICAL"
            output_and_log "Content:" "system" "INFO"
            grep -i 'miner\|xmr\|monero\|bitcoin\|eth\|gpu\|cpu' "$file" | head -5 | while read line; do
                output_and_log "    $line" "system" "INFO"
            done
            echo ""
        done
    else
        output_and_log "No files with suspicious content found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files in unusual locations
    print_command_info "Files in Unusual Locations Check" "find / -name '*miner*' -o -name '*xmr*' -o -name '*monero*' -o -name '*bitcoin*' -o -name '*eth*' 2>/dev/null | grep -v '/proc\|/sys\|/dev'" "system"
    output_and_log "=== Files in Unusual Locations ===" "system"
    local unusual_location_files=$(find / -name '*miner*' -o -name '*xmr*' -o -name '*monero*' -o -name '*bitcoin*' -o -name '*eth*' 2>/dev/null | grep -v '/proc\|/sys\|/dev')
    if [[ -n "$unusual_location_files" ]]; then
        output_and_log "CRITICAL: Files in unusual locations found:" "system" "CRITICAL"
        echo "$unusual_location_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "CRITICAL"
        done
    else
        output_and_log "No files in unusual locations found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual names
    print_command_info "Files with Unusual Names Check" "find / -name '[0-9a-f]{32}' -o -name '[a-z]{1,2}[0-9]{1,2}' 2>/dev/null | grep -v '/proc\|/sys\|/dev'" "system"
    output_and_log "=== Files with Unusual Names ===" "system"
    local unusual_name_files=$(find / -name '[0-9a-f]{32}' -o -name '[a-z]{1,2}[0-9]{1,2}' 2>/dev/null | grep -v '/proc\|/sys\|/dev')
    if [[ -n "$unusual_name_files" ]]; then
        output_and_log "WARNING: Files with unusual names found:" "system" "WARNING"
        echo "$unusual_name_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No files with unusual names found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual sizes
    print_command_info "Files with Unusual Sizes Check" "find /tmp /var/tmp /dev/shm -size +100M -type f" "system"
    output_and_log "=== Large Files in Temporary Directories ===" "system"
    local large_files=$(find /tmp /var/tmp /dev/shm -size +100M -type f 2>/dev/null)
    if [[ -n "$large_files" ]]; then
        output_and_log "WARNING: Large files in temporary directories found:" "system" "WARNING"
        echo "$large_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No large files found in temporary directories" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual timestamps
    print_command_info "Files with Unusual Timestamps Check" "find /tmp /var/tmp /dev/shm -newermt '1 hour ago' -type f" "system"
    output_and_log "=== Recently Created Files (Last Hour) ===" "system"
    local recent_created_files=$(find /tmp /var/tmp /dev/shm -newermt '1 hour ago' -type f 2>/dev/null)
    if [[ -n "$recent_created_files" ]]; then
        output_and_log "WARNING: Recently created files found:" "system" "WARNING"
        echo "$recent_created_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No recently created files found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual owners
    print_command_info "Files with Unusual Owners Check" "find /tmp /var/tmp /dev/shm -not -user root -type f" "system"
    output_and_log "=== Files with Unusual Owners ===" "system"
    local unusual_owner_files=$(find /tmp /var/tmp /dev/shm -not -user root -type f 2>/dev/null)
    if [[ -n "$unusual_owner_files" ]]; then
        output_and_log "WARNING: Files with unusual owners found:" "system" "WARNING"
        echo "$unusual_owner_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No files with unusual owners found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual groups
    print_command_info "Files with Unusual Groups Check" "find /tmp /var/tmp /dev/shm -not -group root -type f" "system"
    output_and_log "=== Files with Unusual Groups ===" "system"
    local unusual_group_files=$(find /tmp /var/tmp /dev/shm -not -group root -type f 2>/dev/null)
    if [[ -n "$unusual_group_files" ]]; then
        output_and_log "WARNING: Files with unusual groups found:" "system" "WARNING"
        echo "$unusual_group_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "WARNING"
        done
    else
        output_and_log "No files with unusual groups found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual extensions
    print_command_info "Files with Unusual Extensions Check" "find /tmp /var/tmp /dev/shm -name '*.exe' -o -name '*.bat' -o -name '*.cmd' -o -name '*.vbs' -o -name '*.js' -o -name '*.jar'" "system"
    output_and_log "=== Files with Unusual Extensions ===" "system"
    local unusual_ext_files=$(find /tmp /var/tmp /dev/shm -name '*.exe' -o -name '*.bat' -o -name '*.cmd' -o -name '*.vbs' -o -name '*.js' -o -name '*.jar' 2>/dev/null)
    if [[ -n "$unusual_ext_files" ]]; then
        output_and_log "CRITICAL: Files with unusual extensions found:" "system" "CRITICAL"
        echo "$unusual_ext_files" | while read file; do
            local file_info=$(ls -la "$file" 2>/dev/null)
            output_and_log "  - $file_info" "system" "CRITICAL"
        done
    else
        output_and_log "No files with unusual extensions found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual content types
    print_command_info "Files with Unusual Content Types Check" "find /tmp /var/tmp /dev/shm -type f -exec file {} \; | grep -i 'executable\|script\|archive'" "system"
    output_and_log "=== Files with Unusual Content Types ===" "system"
    local unusual_content_types=$(find /tmp /var/tmp /dev/shm -type f -exec file {} \; 2>/dev/null | grep -i 'executable\|script\|archive')
    if [[ -n "$unusual_content_types" ]]; then
        output_and_log "WARNING: Files with unusual content types found:" "system" "WARNING"
        echo "$unusual_content_types" | while read line; do
            output_and_log "  - $line" "system" "WARNING"
        done
    else
        output_and_log "No files with unusual content types found" "system" "SUCCESS"
    fi
    echo ""
    
    # Check for files with unusual checksums
    print_command_info "Files with Unusual Checksums Check" "find /tmp /var/tmp /dev/shm -type f -exec md5sum {} \;" "system"
    output_and_log "=== Files with Checksums ===" "system"
    find /tmp /var/tmp /dev/shm -type f 2>/dev/null | head -10 | while read file; do
        local checksum=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)
        output_and_log "$file: $checksum" "system" "INFO"
    done
    echo ""
    
    log_message "INFO" "System investigation module completed" "system"
}

# Execute system investigation
system_investigation 