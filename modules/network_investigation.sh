#!/bin/sh
# Network Investigation Module
# Checks suspicious IPs, ports, connections, etc.

# SCRIPT_DIR should be set by the calling script
# If not set, try to determine it
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
fi

. "$SCRIPT_DIR/utils/utils.sh"
. "$SCRIPT_DIR/config.sh"

investigate_network() {
    local log_file="$LOG_NETWORK"
    
    # Check if log file path is set
    if [ -z "$log_file" ]; then
        print_error "LOG_NETWORK is not set. Cannot create log file."
        return 1
    fi
    
    # Initialize log file with header
    {
        echo "=========================================="
        echo "Network Investigation Module"
        echo "Started: $(get_date)"
        echo "=========================================="
        echo ""
    } > "$log_file" 2>/dev/null || {
        print_error "Failed to create log file: $log_file"
        return 1
    }
    
    print_section "Network Investigation Module"
    
    # Check listening ports
    if should_investigate "minimal"; then
        if bb which netstat >/dev/null 2>&1; then
            execute_and_log "Check listening ports (netstat)" \
                "bb netstat -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null" \
                "$log_file" "minimal"
        elif bb which ss >/dev/null 2>&1; then
            execute_and_log "Check listening ports (ss)" \
                "ss -tulpn 2>/dev/null" \
                "$log_file" "minimal"
        else
            print_warning "netstat and ss not available, trying /proc/net/tcp"
            execute_and_log "Check listening ports (from /proc)" \
                "bb cat /proc/net/tcp /proc/net/udp 2>/dev/null | bb head -50" \
                "$log_file" "minimal"
        fi
    fi
    
    # Check established connections
    if should_investigate "normal"; then
        if bb which netstat >/dev/null 2>&1; then
            execute_and_log "Check established connections" \
                "bb netstat -anp 2>/dev/null | bb grep ESTAB || netstat -anp 2>/dev/null | bb grep ESTAB" \
                "$log_file" "normal"
        elif bb which ss >/dev/null 2>&1; then
            execute_and_log "Check established connections (ss)" \
                "ss -anp 2>/dev/null | bb grep ESTAB" \
                "$log_file" "normal"
        fi
    fi
    
    # Check SSH brute force attempts from auth.log
    if should_investigate "normal"; then
        if [ -f /var/log/auth.log ]; then
            execute_and_log "Check SSH brute force attempts (top 20 IPs)" \
                "bb cat /var/log/auth.log 2>/dev/null | bb grep 'sshd' | bb grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | bb sort | bb uniq -c | bb sort -nr | bb head -20" \
                "$log_file" "normal"
        elif [ -f /var/log/secure ]; then
            execute_and_log "Check SSH brute force attempts from secure log (top 20 IPs)" \
                "bb cat /var/log/secure 2>/dev/null | bb grep 'sshd' | bb grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | bb sort | bb uniq -c | bb sort -nr | bb head -20" \
                "$log_file" "normal"
        fi
    fi
    
    # Check for mining pool connections
    if should_investigate "detailed"; then
        local mining_domains="stratum+tcp pool mine xmr monero bitcoin"
        for domain in $mining_domains; do
            if bb which netstat >/dev/null 2>&1; then
                execute_and_log "Check connections to mining-related domains ($domain)" \
                    "bb netstat -anp 2>/dev/null | bb grep -i $domain || echo 'No connections found'" \
                    "$log_file" "detailed"
            fi
        done
    fi
    
    # Check DNS configuration
    if should_investigate "normal"; then
        if [ -f /etc/resolv.conf ]; then
            execute_and_log "Check DNS configuration" \
                "bb cat /etc/resolv.conf" \
                "$log_file" "normal"
        fi
    fi
    
    # Check /etc/hosts for suspicious entries
    if should_investigate "normal"; then
        execute_and_log "Check /etc/hosts for suspicious entries" \
            "bb cat /etc/hosts" \
            "$log_file" "normal"
        
        local suspicious_hosts=$(bb cat /etc/hosts 2>/dev/null | bb grep -v '^#' | bb grep -v '^$' | bb grep -v '127.0.0.1\|::1')
        if [ -n "$suspicious_hosts" ]; then
            print_warning "Suspicious entries in /etc/hosts:"
            echo "$suspicious_hosts"
            log_to_file "$log_file" "WARNING: Suspicious /etc/hosts entries: $suspicious_hosts"
        fi
    fi
    
    # Check network interfaces
    if should_investigate "normal"; then
        if bb which ifconfig >/dev/null 2>&1; then
            execute_and_log "Check network interfaces" \
                "ifconfig -a 2>/dev/null || bb ifconfig -a 2>/dev/null" \
                "$log_file" "normal"
        elif [ -d /sys/class/net ]; then
            execute_and_log "Check network interfaces (from /sys)" \
                "bb ls -la /sys/class/net/" \
                "$log_file" "normal"
        fi
    fi
    
    # Check iptables rules
    if should_investigate "detailed"; then
        if bb which iptables >/dev/null 2>&1; then
            execute_and_log "Check iptables rules" \
                "iptables -L -n -v 2>/dev/null | bb head -50" \
                "$log_file" "detailed"
        fi
    fi
    
    # Check recent network connections from logs
    if should_investigate "detailed"; then
        if [ -f /var/log/syslog ]; then
            execute_and_log "Check recent network-related log entries" \
                "bb cat /var/log/syslog 2>/dev/null | bb grep -i 'network\|connection\|firewall' | bb tail -50" \
                "$log_file" "detailed"
        fi
    fi
    
    # Summary
    print_section "Network Investigation Summary"
    local listen_count=0
    if bb which netstat >/dev/null 2>&1; then
        listen_count=$(bb netstat -tuln 2>/dev/null | bb wc -l)
    elif bb which ss >/dev/null 2>&1; then
        listen_count=$(ss -tuln 2>/dev/null | bb wc -l)
    fi
    
    echo "Listening ports/services: $listen_count"
    echo ""
    
    log_to_file "$log_file" "SUMMARY: Listening ports: $listen_count"
    
    print_success "Network investigation completed"
}

# Run if executed directly
if [ "${0##*/}" = "network_investigation.sh" ]; then
    if [ -z "$SCRIPT_DIR" ]; then
        SCRIPT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
    fi
    export SCRIPT_DIR
    . "$SCRIPT_DIR/config.sh"
    set_log_paths "$(get_timestamp)"
    investigate_network
fi

