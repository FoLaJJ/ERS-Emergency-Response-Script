#!/bin/sh
# Main Emergency Response Script for Mining Incident
# This script runs all investigation modules and generates reports

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Export SCRIPT_DIR so sourced scripts can use it
export SCRIPT_DIR

# Source configuration and utilities
. "$SCRIPT_DIR/config.sh"
. "$SCRIPT_DIR/utils/utils.sh"

# Initialize
init_busybox
RESULTS_DIR=$(create_results_dir)
TIMESTAMP=$(get_timestamp)

# Set log file paths
set_log_paths "$TIMESTAMP"

# Verify log paths are set (they should be exported by set_log_paths)
if [ -z "$LOG_USER" ]; then
    print_error "Failed to set log file paths"
    exit 1
fi

# Create results directory if it doesn't exist
bb mkdir -p "$RESULTS_DIR"

# Print banner
echo ""
echo "${PURPLE}${BOLD}========================================${NC}"
echo "${PURPLE}${BOLD}  Mining Incident Response Script${NC}"
echo "${PURPLE}${BOLD}  Emergency Response System${NC}"
echo "${PURPLE}${BOLD}========================================${NC}"
echo ""
echo "${CYAN}Start Time:${NC} $(get_date)"
echo "${CYAN}Investigation Level:${NC} $INVESTIGATION_LEVEL"
echo "${CYAN}Results Directory:${NC} $RESULTS_DIR"
echo "${CYAN}Timestamp:${NC} $TIMESTAMP"
echo ""

# Create summary file
SUMMARY_FILE="$LOG_SUMMARY"
INDEX_FILE="$LOG_INDEX"

# Initialize summary
{
    echo "=========================================="
    echo "Mining Incident Response Report"
    echo "=========================================="
    echo "Start Time: $(get_date)"
    echo "Investigation Level: $INVESTIGATION_LEVEL"
    echo "System Type: $SYSTEM_TYPE"
    echo "Timestamp: $TIMESTAMP"
    echo ""
    echo "=========================================="
    echo "Investigation Modules"
    echo "=========================================="
} > "$SUMMARY_FILE"

{
    echo "Emergency Response Script Results Index"
    echo "========================================"
    echo "Generated: $(get_date)"
    echo "Timestamp: $TIMESTAMP"
    echo ""
    echo "Log Files:"
} > "$INDEX_FILE"

# Run investigation modules
print_section "Starting Investigation Modules"

# Module 1: User Investigation
echo "${GREEN}Running User Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/user_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/user_investigation.sh"
    investigate_users
    echo "User Investigation: $LOG_USER" >> "$INDEX_FILE"
    echo "✓ User Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "User investigation module not found"
    echo "✗ User Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 2: Command Investigation
echo "${GREEN}Running Command Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/command_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/command_investigation.sh"
    investigate_commands
    echo "Command Investigation: $LOG_COMMAND" >> "$INDEX_FILE"
    echo "✓ Command Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Command investigation module not found"
    echo "✗ Command Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 3: Network Investigation
echo "${GREEN}Running Network Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/network_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/network_investigation.sh"
    investigate_network
    echo "Network Investigation: $LOG_NETWORK" >> "$INDEX_FILE"
    echo "✓ Network Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Network investigation module not found"
    echo "✗ Network Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 4: Process Investigation
echo "${GREEN}Running Process Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/process_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/process_investigation.sh"
    investigate_processes
    echo "Process Investigation: $LOG_PROCESS" >> "$INDEX_FILE"
    echo "✓ Process Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Process investigation module not found"
    echo "✗ Process Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 5: Startup Investigation
echo "${GREEN}Running Startup Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/startup_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/startup_investigation.sh"
    investigate_startup
    echo "Startup Investigation: $LOG_STARTUP" >> "$INDEX_FILE"
    echo "✓ Startup Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Startup investigation module not found"
    echo "✗ Startup Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 6: Cron Investigation
echo "${GREEN}Running Cron Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/cron_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/cron_investigation.sh"
    investigate_cron
    echo "Cron Investigation: $LOG_CRON" >> "$INDEX_FILE"
    echo "✓ Cron Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Cron investigation module not found"
    echo "✗ Cron Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 7: Log Investigation
echo "${GREEN}Running Log Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/log_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/log_investigation.sh"
    investigate_logs
    echo "Log Investigation: $LOG_LOG" >> "$INDEX_FILE"
    echo "✓ Log Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "Log investigation module not found"
    echo "✗ Log Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Module 8: System Investigation
echo "${GREEN}Running System Investigation Module...${NC}"
if [ -f "$SCRIPT_DIR/modules/system_investigation.sh" ]; then
    . "$SCRIPT_DIR/modules/system_investigation.sh"
    investigate_system
    echo "System Investigation: $LOG_SYSTEM" >> "$INDEX_FILE"
    echo "✓ System Investigation completed" >> "$SUMMARY_FILE"
else
    print_error "System investigation module not found"
    echo "✗ System Investigation failed (module not found)" >> "$SUMMARY_FILE"
fi
echo ""

# Finalize summary
{
    echo ""
    echo "=========================================="
    echo "Investigation Complete"
    echo "=========================================="
    echo "End Time: $(get_date)"
    echo ""
    echo "All results have been saved to: $RESULTS_DIR"
    echo "Summary file: $SUMMARY_FILE"
    echo "Index file: $INDEX_FILE"
} >> "$SUMMARY_FILE"

echo "" >> "$INDEX_FILE"
echo "Summary: $LOG_SUMMARY" >> "$INDEX_FILE"

# Print final summary
print_section "Investigation Complete"
echo "${GREEN}All investigation modules have completed.${NC}"
echo ""
echo "${CYAN}Results Location:${NC} $RESULTS_DIR"
echo "${CYAN}Summary File:${NC} $SUMMARY_FILE"
echo "${CYAN}Index File:${NC} $INDEX_FILE"
echo ""
echo "${YELLOW}To view results in web interface, run:${NC}"
echo "  ./start_web_viewer.sh"
echo ""
echo "${CYAN}End Time:${NC} $(get_date)"
echo ""

# Save timestamp for web viewer
echo "$TIMESTAMP" > "$RESULTS_DIR/.last_run_timestamp"

print_success "Emergency response investigation completed successfully!"

