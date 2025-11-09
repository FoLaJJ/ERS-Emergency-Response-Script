#!/bin/sh
# Web Viewer Startup Script
# Starts busybox httpd server to view investigation results

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Export SCRIPT_DIR so sourced scripts can use it
export SCRIPT_DIR

# Source configuration and utilities
. "$SCRIPT_DIR/config.sh"
. "$SCRIPT_DIR/utils/utils.sh"

# Initialize
init_busybox

# Check if results directory exists
if [ ! -d "$RESULTS_DIR" ]; then
    print_error "Results directory not found: $RESULTS_DIR"
    print_error "Please run start_mining_incident_response.sh first"
    exit 1
fi

# Get last run timestamp
LAST_TIMESTAMP=""
if [ -f "$RESULTS_DIR/.last_run_timestamp" ]; then
    LAST_TIMESTAMP=$(bb cat "$RESULTS_DIR/.last_run_timestamp")
else
    # Find the most recent timestamp from log files
    LAST_TIMESTAMP=$(bb ls -t "$RESULTS_DIR"/*.log 2>/dev/null | bb head -1 | bb sed 's/.*_\([0-9]\{8\}_[0-9]\{6\}\)\.log/\1/')
fi

if [ -z "$LAST_TIMESTAMP" ]; then
    print_error "No investigation results found. Please run start_mining_incident_response.sh first"
    exit 1
fi

print_section "Web Viewer Startup"

# Set log file paths with last timestamp
set_log_paths "$LAST_TIMESTAMP"

# Create web output directory
bb mkdir -p "$WEB_DIR"

# Generate random password
WEB_PASSWORD=$(generate_password)
WEB_PASSWORD_FILE="$WEB_DIR/.password"

# Save password to file
echo "$WEB_PASSWORD" > "$WEB_PASSWORD_FILE"
bb chmod 600 "$WEB_PASSWORD_FILE"

# Generate unique session ID for this web server instance
# This ensures that old cached sessions cannot access new server instances
WEB_SESSION_ID=$(generate_session_id)
WEB_SESSION_FILE="$WEB_DIR/.session_id"

# Save session ID to file
echo "$WEB_SESSION_ID" > "$WEB_SESSION_FILE"
bb chmod 600 "$WEB_SESSION_FILE"

# Generate HTML files from templates
generate_html_files() {
    local lock_template="$SCRIPT_DIR/templates/lock.html"
    local index_template="$SCRIPT_DIR/templates/index.html"
    local lock_html="$WEB_DIR/lock.html"
    local index_html="$WEB_DIR/index.html"
    
    # Verify LOG_* variables are set
    if [ -z "$LOG_USER" ] || [ -z "$LOG_COMMAND" ] || [ -z "$LOG_NETWORK" ] || \
       [ -z "$LOG_PROCESS" ] || [ -z "$LOG_STARTUP" ] || [ -z "$LOG_CRON" ] || \
       [ -z "$LOG_LOG" ] || [ -z "$LOG_SYSTEM" ]; then
        print_error "LOG_* variables are not set. Did set_log_paths() run correctly?"
        print_error "LAST_TIMESTAMP: $LAST_TIMESTAMP"
        print_error "RESULTS_DIR: $RESULTS_DIR"
        return 1
    fi
    
    # Check if templates exist
    if [ ! -f "$lock_template" ]; then
        print_error "Template file not found: $lock_template"
        return 1
    fi
    
    if [ ! -f "$index_template" ]; then
        print_error "Template file not found: $index_template"
        return 1
    fi
    
    # Create css directory in web output and copy CSS files
    local css_dir="$WEB_DIR/css"
    local templates_css_dir="$SCRIPT_DIR/templates/css"
    mkdir -p "$css_dir" 2>/dev/null || {
        print_error "Failed to create css directory: $css_dir"
        return 1
    }
    
    # Copy CSS files
    print_info "Copying CSS files..."
    if [ -f "$templates_css_dir/index.css" ]; then
        if bb cp "$templates_css_dir/index.css" "$css_dir/index.css" 2>/dev/null; then
            print_info "Copied index.css"
        else
            print_warning "Failed to copy index.css"
        fi
    else
        print_warning "CSS file not found: $templates_css_dir/index.css"
    fi
    
    if [ -f "$templates_css_dir/lock.css" ]; then
        if bb cp "$templates_css_dir/lock.css" "$css_dir/lock.css" 2>/dev/null; then
            print_info "Copied lock.css"
        else
            print_warning "Failed to copy lock.css"
        fi
    else
        print_warning "CSS file not found: $templates_css_dir/lock.css"
    fi
    
    # Escape password for JavaScript (escape backslashes, quotes, etc.)
    local escaped_password=$(echo "$WEB_PASSWORD" | bb sed 's/\\/\\\\/g; s/"/\\"/g; s/'"'"'/\\'"'"'/g')
    
    # Escape session ID for JavaScript
    local escaped_session_id=$(echo "$WEB_SESSION_ID" | bb sed 's/\\/\\\\/g; s/"/\\"/g; s/'"'"'/\\'"'"'/g')
    
    # Generate lock.html from template
    print_info "Generating lock.html from template..."
    bb cat "$lock_template" 2>/dev/null | \
        bb sed "s|PASSWORD_PLACEHOLDER|$escaped_password|g" | \
        bb sed "s|SESSION_ID_PLACEHOLDER|$escaped_session_id|g" > "$lock_html"
    
    # Generate index.html from template
    print_info "Generating index.html from template..."
    
    # Create logs directory in web output for frontend to access log files
    local logs_dir="$WEB_DIR/logs"
    mkdir -p "$logs_dir" 2>/dev/null || {
        print_error "Failed to create logs directory: $logs_dir"
        return 1
    }
    
    # Copy log files to web directory - simple and clean!
    # Frontend JavaScript will read them via fetch API
    print_info "Copying log files to web directory..."
    
    copy_log_file() {
        local source_file="$1"
        local target_file="$2"
        local log_name="$3"
        
        if [ -z "$source_file" ]; then
            print_warning "Log file path is empty for $log_name"
            # Create empty file
            echo -n "" > "$target_file" 2>/dev/null || true
            return
        fi
        
        if [ ! -f "$source_file" ]; then
            print_warning "Log file not found: $source_file (for $log_name)"
            # Create empty file so frontend doesn't get 404
            echo -n "" > "$target_file" 2>/dev/null || true
            return
        fi
        
        if [ ! -s "$source_file" ]; then
            print_warning "Log file is empty: $source_file (for $log_name)"
            # Create empty file
            echo -n "" > "$target_file" 2>/dev/null || true
            return
        fi
        
        # Simply copy the file - frontend will handle HTML escaping via JavaScript
        if bb cp "$source_file" "$target_file" 2>/dev/null; then
            print_info "Copied $log_name: $(bb basename "$source_file")"
        else
            print_error "Failed to copy log file: $source_file (for $log_name)"
            # Create empty file as fallback
            echo -n "" > "$target_file" 2>/dev/null || true
        fi
    }
    
    # Copy all log files to logs/ directory
    copy_log_file "$LOG_USER" "$logs_dir/user.log" "user"
    copy_log_file "$LOG_COMMAND" "$logs_dir/command.log" "command"
    copy_log_file "$LOG_NETWORK" "$logs_dir/network.log" "network"
    copy_log_file "$LOG_PROCESS" "$logs_dir/process.log" "process"
    copy_log_file "$LOG_STARTUP" "$logs_dir/startup.log" "startup"
    copy_log_file "$LOG_CRON" "$logs_dir/cron.log" "cron"
    copy_log_file "$LOG_LOG" "$logs_dir/log.log" "log"
    copy_log_file "$LOG_SYSTEM" "$logs_dir/system.log" "system"
    
    # Generate index.html - only replace simple placeholders
    # Frontend JavaScript will load log files via fetch API
    print_info "Generating index.html from template..."
    bb cat "$index_template" 2>/dev/null | \
        bb sed "s|TIMESTAMP_PLACEHOLDER|$LAST_TIMESTAMP|g" | \
        bb sed "s|LEVEL_PLACEHOLDER|$INVESTIGATION_LEVEL|g" | \
        bb sed "s|SYSTEM_PLACEHOLDER|$SYSTEM_TYPE|g" | \
        bb sed "s|DATE_PLACEHOLDER|$(get_date)|g" | \
        bb sed "s|PASSWORD_DISPLAY_PLACEHOLDER|$WEB_PASSWORD|g" | \
        bb sed "s|SESSION_ID_PLACEHOLDER|$escaped_session_id|g" > "$index_html"
    
    if [ ! -s "$index_html" ]; then
        print_error "Failed to generate index.html"
        return 1
    fi
    
    print_success "HTML files generated successfully"
    print_info "Log files are available in: $logs_dir"
}

# Note: Log files are copied to web_output/logs/ directory
# Frontend JavaScript loads log files via fetch API and handles HTML escaping
# Users must be authenticated to view the index.html page
# The web interface uses a sidebar navigation to switch between different investigation modules

# Generate HTML files (logs are served as static files, loaded by frontend JavaScript)
generate_html_files

# Note: 
# - lock.html is the password entry page (authentication page)
# - index.html is the main results page (requires authentication)
# - When users access index.html without authentication, they will be redirected to lock.html
# - When users access the root URL, busybox httpd will serve index.html, which will redirect to lock.html if not authenticated

# Start busybox httpd
print_section "Starting Web Server"
print_info "Web directory: $WEB_DIR"
print_info "Port: $WEB_PORT"
print_warning "Access Password: $WEB_PASSWORD"
echo ""
print_info "Server will be accessible at:"
print_info "  - http://localhost:$WEB_PORT/ (will redirect to lock.html)"
print_info "  - http://localhost:$WEB_PORT/lock.html (password entry page)"
print_info "  - http://localhost:$WEB_PORT/index.html (results page, requires authentication)"
print_info "  - http://127.0.0.1:$WEB_PORT/ (same as localhost)"
echo ""
print_info "Note: To access from network, replace 'localhost' with your server's IP address"
echo ""
print_warning "Press Ctrl+C to stop the server"
echo ""

# Change to web directory and start httpd
cd "$WEB_DIR"

# Start busybox httpd in foreground
# Note: busybox httpd serves files from the current directory
"$BUSYBOX" httpd -f -p "$WEB_PORT" -h "$WEB_DIR" || {
    print_error "Failed to start busybox httpd"
    print_error "Make sure port $WEB_PORT is not in use"
    exit 1
}
