#!/bin/bash

# Network Investigation Module
# Checks for suspicious IPs, port scanning, network connections, and brute force attempts

network_investigation() {
    print_section "NETWORK INVESTIGATION"
    
    log_message "INFO" "Starting network investigation module" "network"
    
    # Check current network connections
    print_command_info "Network Connections Check" "netstat -anp" "network"
    output_and_log "=== Current Network Connections ===" "network"
    output_and_log "Active Connections:" "network" "INFO"
    netstat -anp | grep ESTABLISHED | while read line; do
        output_and_log "  $line" "network" "INFO"
    done
    echo ""
    
    # Check listening ports
    print_command_info "Listening Ports Check" "netstat -tuln" "network"
    output_and_log "=== Listening Ports ===" "network"
    output_and_log "Port\tProtocol\tState\t\tService" "network" "INFO"
    output_and_log "----\t--------\t-----\t\t-------" "network" "INFO"
    netstat -tuln | grep LISTEN | while read proto recv send local foreign state; do
        local port=$(echo "$local" | awk -F: '{print $NF}')
        local service=$(grep -w "$port" /etc/services 2>/dev/null | head -1 | awk '{print $1}')
        output_and_log "$port\t$proto\tLISTEN\t\t$service" "network" "INFO"
    done
    echo ""
    
    # Check for suspicious ports (common mining ports)
    print_command_info "Suspicious Ports Check" "netstat -tuln | grep -E ':(3333|14444|14433|45560|14466|14467|14468|14469|14470|14471|14472|14473|14474|14475|14476|14477|14478|14479|14480|14481|14482|14483|14484|14485|14486|14487|14488|14489|14490|14491|14492|14493|14494|14495|14496|14497|14498|14499|14500)'" "network"
    output_and_log "=== Suspicious Ports (Common Mining Ports) ===" "network"
    local suspicious_ports=$(netstat -tuln | grep -E ':(3333|14444|14433|45560|14466|14467|14468|14469|14470|14471|14472|14473|14474|14475|14476|14477|14478|14479|14480|14481|14482|14483|14484|14485|14486|14487|14488|14489|14490|14491|14492|14493|14494|14495|14496|14497|14498|14499|14500)')
    if [[ -n "$suspicious_ports" ]]; then
        output_and_log "CRITICAL: Suspicious mining ports found:" "network" "CRITICAL"
        echo "$suspicious_ports" | while read line; do
            output_and_log "  - $line" "network" "CRITICAL"
        done
        echo "$suspicious_ports" > "$TEMP_DIR/suspicious_connections.txt"
    else
        output_and_log "No suspicious mining ports found" "network" "SUCCESS"
    fi
    echo ""
    
    # Check for SSH brute force attempts
    print_command_info "SSH Brute Force Check" "cat /var/log/auth.log | grep 'sshd' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | sort | uniq -c | sort -nr" "network"
    output_and_log "=== SSH Brute Force Attempts ===" "network"
    if [[ -f /var/log/auth.log ]]; then
        local ssh_attempts=$(cat /var/log/auth.log | grep "sshd" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq -c | sort -nr | head -10)
        if [[ -n "$ssh_attempts" ]]; then
            output_and_log "WARNING: SSH brute force attempts detected:" "network" "WARNING"
            echo "$ssh_attempts" | while read count ip; do
                output_and_log "  $count attempts from $ip" "network" "WARNING"
            done
        else
            output_and_log "No SSH brute force attempts detected" "network" "SUCCESS"
        fi
    else
        output_and_log "Auth log not found" "network" "WARNING"
    fi
    echo ""
    
    # Check for failed login attempts
    print_command_info "Failed Login Attempts Check" "cat /var/log/auth.log | grep 'Failed password'" "network"
    output_and_log "=== Failed Login Attempts ===" "network"
    if [[ -f /var/log/auth.log ]]; then
        local failed_logins=$(cat /var/log/auth.log | grep "Failed password" | tail -10)
        if [[ -n "$failed_logins" ]]; then
            output_and_log "WARNING: Recent failed login attempts:" "network" "WARNING"
            echo "$failed_logins" | while read line; do
                output_and_log "  $line" "network" "WARNING"
            done
        else
            output_and_log "No recent failed login attempts" "network" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check for successful logins
    print_command_info "Successful Logins Check" "cat /var/log/auth.log | grep 'Accepted password'" "network"
    output_and_log "=== Successful Logins ===" "network"
    if [[ -f /var/log/auth.log ]]; then
        local successful_logins=$(cat /var/log/auth.log | grep "Accepted password" | tail -10)
        if [[ -n "$successful_logins" ]]; then
            output_and_log "Recent successful logins:" "network" "INFO"
            echo "$successful_logins" | while read line; do
                output_and_log "  $line" "network" "INFO"
            done
        else
            output_and_log "No recent successful logins found" "network" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check for unusual network activity
    print_command_info "Unusual Network Activity Check" "ss -tuln" "network"
    output_and_log "=== Unusual Network Activity ===" "network"
    local unusual_connections=$(ss -tuln | grep -v "127.0.0.1\|::1" | grep -E ":(3333|14444|14433|45560|14466|14467|14468|14469|14470)")
    if [[ -n "$unusual_connections" ]]; then
        output_and_log "CRITICAL: Unusual network connections found:" "network" "CRITICAL"
        echo "$unusual_connections" | while read line; do
            output_and_log "  - $line" "network" "CRITICAL"
        done
    else
        output_and_log "No unusual network connections found" "network" "SUCCESS"
    fi
    echo ""
    
    # Check for DNS queries
    print_command_info "DNS Queries Check" "cat /var/log/syslog | grep 'dnsmasq' | tail -10" "network"
    output_and_log "=== Recent DNS Queries ===" "network"
    if [[ -f /var/log/syslog ]]; then
        local dns_queries=$(cat /var/log/syslog | grep "dnsmasq" | tail -10)
        if [[ -n "$dns_queries" ]]; then
            output_and_log "Recent DNS queries:" "network" "INFO"
            echo "$dns_queries" | while read line; do
                output_and_log "  $line" "network" "INFO"
            done
        else
            output_and_log "No recent DNS queries found" "network" "SUCCESS"
        fi
    fi
    echo ""
    
    # Check for outbound connections to known mining pools
    print_command_info "Mining Pool Connections Check" "ss -tuln | grep -E '(stratum|pool|mine)'" "network"
    output_and_log "=== Mining Pool Connections ===" "network"
    local mining_connections=$(ss -tuln | grep -E "(stratum|pool|mine)" 2>/dev/null)
    if [[ -n "$mining_connections" ]]; then
        output_and_log "CRITICAL: Possible mining pool connections found:" "network" "CRITICAL"
        echo "$mining_connections" | while read line; do
            output_and_log "  - $line" "network" "CRITICAL"
        done
    else
        output_and_log "No mining pool connections found" "network" "SUCCESS"
    fi
    echo ""
    
    # Check for network interfaces
    print_command_info "Network Interfaces Check" "ip addr show" "network"
    output_and_log "=== Network Interfaces ===" "network"
    ip addr show | while read line; do
        output_and_log "$line" "network" "INFO"
    done
    echo ""
    
    # Check for routing table
    print_command_info "Routing Table Check" "ip route show" "network"
    output_and_log "=== Routing Table ===" "network"
    ip route show | while read line; do
        output_and_log "$line" "network" "INFO"
    done
    echo ""
    
    # Check for firewall rules
    print_command_info "Firewall Rules Check" "iptables -L" "network"
    output_and_log "=== Firewall Rules ===" "network"
    iptables -L 2>/dev/null | while read line; do
        output_and_log "$line" "network" "INFO"
    done
    echo ""
    
    log_message "INFO" "Network investigation module completed" "network"
}

# Execute network investigation
network_investigation 