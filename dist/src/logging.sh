#!/usr/bin/env bash
# logging.sh - Enhanced logging functions for NetHunter Installer
# Version: 3.0 (May 2025)

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
    source "$SCRIPT_DIR/utils.sh"
fi

# ===== Enhanced Logging Functions =====

# Initialize logging system
nh_logging_init() {
    nh_log "INFO" "Initializing enhanced logging system"
    
    # Create log directory with proper permissions
    mkdir -p "$NH_LOG_DIR"
    chmod 700 "$NH_LOG_DIR"
    
    # Set up log rotation
    nh_logging_rotate
    
    # Create log file with timestamp
    NH_LOG_FILE="$NH_LOG_DIR/nethunter_$(date +%Y%m%d_%H%M%S).log"
    touch "$NH_LOG_FILE"
    chmod 600 "$NH_LOG_FILE"
    
    # Log header information
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "NetHunter Installer Log - Version $NH_VERSION" >> "$NH_LOG_FILE"
    echo "Started: $(date)" >> "$NH_LOG_FILE"
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "" >> "$NH_LOG_FILE"
    
    # Log detailed system information
    nh_logging_system_info
    
    nh_log "SUCCESS" "Logging system initialized"
    return 0
}

# Log detailed system information
nh_logging_system_info() {
    nh_log "INFO" "Collecting detailed system information"
    
    # Create a separator in the log
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "SYSTEM INFORMATION" >> "$NH_LOG_FILE"
    echo "=======================================================" >> "$NH_LOG_FILE"
    
    # Basic system info
    echo "Date and Time: $(date)" >> "$NH_LOG_FILE"
    echo "Hostname: $(hostname 2>/dev/null || echo 'Unknown')" >> "$NH_LOG_FILE"
    echo "Kernel: $(uname -a)" >> "$NH_LOG_FILE"
    
    # CPU information
    if [ -f "/proc/cpuinfo" ]; then
        echo "CPU: $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | sed 's/^[ \t]*//')" >> "$NH_LOG_FILE"
        echo "CPU Cores: $(grep -c "processor" /proc/cpuinfo)" >> "$NH_LOG_FILE"
    else
        echo "CPU: Unknown" >> "$NH_LOG_FILE"
    fi
    
    # Memory information
    if [ -f "/proc/meminfo" ]; then
        echo "Total Memory: $(grep "MemTotal" /proc/meminfo | awk '{print $2 " " $3}')" >> "$NH_LOG_FILE"
        echo "Free Memory: $(grep "MemFree" /proc/meminfo | awk '{print $2 " " $3}')" >> "$NH_LOG_FILE"
    else
        echo "Memory: Unknown" >> "$NH_LOG_FILE"
    fi
    
    # Storage information
    echo "Storage:" >> "$NH_LOG_FILE"
    df -h | grep -v "tmpfs" >> "$NH_LOG_FILE"
    
    # Android-specific information
    if [ -f "/system/build.prop" ]; then
        echo "Android Version: $(grep "ro.build.version.release" /system/build.prop | cut -d '=' -f 2)" >> "$NH_LOG_FILE"
        echo "Android SDK: $(grep "ro.build.version.sdk" /system/build.prop | cut -d '=' -f 2)" >> "$NH_LOG_FILE"
        echo "Device: $(grep "ro.product.model" /system/build.prop | cut -d '=' -f 2)" >> "$NH_LOG_FILE"
        echo "Manufacturer: $(grep "ro.product.manufacturer" /system/build.prop | cut -d '=' -f 2)" >> "$NH_LOG_FILE"
    fi
    
    # Termux-specific information
    if [ -d "/data/data/com.termux" ]; then
        echo "Termux Environment: Yes" >> "$NH_LOG_FILE"
        if [ -f "$PREFIX/etc/termux-version" ]; then
            echo "Termux Version: $(cat $PREFIX/etc/termux-version)" >> "$NH_LOG_FILE"
        fi
        
        # List installed packages
        echo "Installed Packages:" >> "$NH_LOG_FILE"
        pkg list-installed 2>/dev/null | head -n 20 >> "$NH_LOG_FILE"
        echo "... (truncated)" >> "$NH_LOG_FILE"
    else
        echo "Termux Environment: No" >> "$NH_LOG_FILE"
    fi
    
    # Network information (basic)
    echo "Network Information:" >> "$NH_LOG_FILE"
    ip addr 2>/dev/null | grep -E "inet " | grep -v "127.0.0.1" >> "$NH_LOG_FILE" || echo "Network info unavailable" >> "$NH_LOG_FILE"
    
    # Internet connectivity check
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "Internet Connectivity: Yes" >> "$NH_LOG_FILE"
    else
        echo "Internet Connectivity: No" >> "$NH_LOG_FILE"
    fi
    
    # Environment variables (filtered)
    echo "Environment Variables (filtered):" >> "$NH_LOG_FILE"
    env | grep -E "^(TERM|SHELL|PATH|LANG|HOME|USER|PREFIX)=" >> "$NH_LOG_FILE"
    
    # End of system information
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "" >> "$NH_LOG_FILE"
    
    nh_log "SUCCESS" "System information collected"
    return 0
}

# Rotate log files
nh_logging_rotate() {
    nh_log "DEBUG" "Checking log rotation"
    
    # Maximum number of log files to keep
    local max_logs=10
    
    # Check if we have more than max_logs log files
    local log_count=$(ls -1 "$NH_LOG_DIR"/*.log 2>/dev/null | wc -l)
    
    if [ "$log_count" -gt "$max_logs" ]; then
        nh_log "INFO" "Rotating log files (keeping newest $max_logs)"
        
        # Delete oldest log files, keeping the newest max_logs
        ls -1t "$NH_LOG_DIR"/*.log | tail -n +$(($max_logs + 1)) | xargs rm -f
    fi
    
    return 0
}

# Log performance metrics
nh_logging_performance() {
    local operation=$1
    local start_time=$2
    local end_time=${3:-$(date +%s)}
    
    # Calculate duration
    local duration=$(($end_time - $start_time))
    
    nh_log "PERFORMANCE" "Operation: $operation, Duration: ${duration}s"
    
    return 0
}

# Log command execution
nh_logging_command() {
    local command=$1
    local start_time=$(date +%s)
    
    nh_log "COMMAND" "Executing: $command"
    
    # Execute command and capture output
    local output
    output=$($command 2>&1)
    local status=$?
    
    local end_time=$(date +%s)
    local duration=$(($end_time - $start_time))
    
    # Log command result
    if [ $status -eq 0 ]; then
        nh_log "COMMAND" "Command succeeded (${duration}s): $command"
    else
        nh_log "ERROR" "Command failed (${duration}s): $command"
        nh_log "ERROR" "Exit code: $status"
    fi
    
    # Log command output (truncated if too long)
    local max_output_lines=50
    local output_lines=$(echo "$output" | wc -l)
    
    if [ $output_lines -gt $max_output_lines ]; then
        nh_log "DEBUG" "Command output (truncated, showing first $max_output_lines lines):"
        echo "$output" | head -n $max_output_lines >> "$NH_LOG_FILE"
        echo "... (truncated, $output_lines total lines)" >> "$NH_LOG_FILE"
    else
        nh_log "DEBUG" "Command output:"
        echo "$output" >> "$NH_LOG_FILE"
    fi
    
    return $status
}

# Send log to remote server
nh_logging_send_remote() {
    local webhook_url=${1:-"$NH_WEBHOOK_URL"}
    local log_file=${2:-"$NH_LOG_FILE"}
    
    if [ -z "$webhook_url" ]; then
        nh_log "DEBUG" "Remote logging disabled (no webhook URL)"
        return 0
    fi
    
    nh_log "INFO" "Sending log to remote server"
    
    # Compress log file
    local compressed_log="$NH_TEMP_DIR/$(basename "$log_file").gz"
    gzip -c "$log_file" > "$compressed_log"
    
    # Add metadata
    local metadata="$NH_TEMP_DIR/metadata.json"
    cat > "$metadata" << EOF
{
  "version": "$NH_VERSION",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "device": "$(uname -m)",
  "status": "$1"
}
EOF
    
    # Send log file with metadata
    if command -v curl >/dev/null 2>&1; then
        curl -s -F "log=@$compressed_log" -F "metadata=@$metadata" "$webhook_url" > /dev/null
        local status=$?
    else
        local status=1
        nh_log "ERROR" "curl not found, cannot send log"
    fi
    
    # Clean up
    rm -f "$compressed_log" "$metadata"
    
    if [ $status -eq 0 ]; then
        nh_log "SUCCESS" "Log sent successfully"
    else
        nh_log "ERROR" "Failed to send log"
    fi
    
    return $status
}

# Create a crash report
nh_logging_crash_report() {
    local error_message=$1
    local error_location=${2:-"unknown"}
    local error_code=${3:-1}
    
    nh_log "ERROR" "Creating crash report for error at $error_location: $error_message (code: $error_code)"
    
    # Create crash report directory
    local crash_dir="$NH_LOG_DIR/crashes"
    mkdir -p "$crash_dir"
    
    # Create crash report file
    local crash_file="$crash_dir/crash_$(date +%Y%m%d_%H%M%S).log"
    
    # Write crash report header
    cat > "$crash_file" << EOF
======================================================
NetHunter Installer Crash Report
======================================================
Version: $NH_VERSION
Date: $(date)
Error Location: $error_location
Error Message: $error_message
Error Code: $error_code
======================================================

EOF
    
    # Append system information
    echo "SYSTEM INFORMATION:" >> "$crash_file"
    echo "Kernel: $(uname -a)" >> "$crash_file"
    if [ -f "/system/build.prop" ]; then
        echo "Android Version: $(grep "ro.build.version.release" /system/build.prop | cut -d '=' -f 2)" >> "$crash_file"
        echo "Device: $(grep "ro.product.model" /system/build.prop | cut -d '=' -f 2)" >> "$crash_file"
    fi
    echo "" >> "$crash_file"
    
    # Append log tail
    echo "LOG TAIL (last 100 lines):" >> "$crash_file"
    echo "======================================================" >> "$crash_file"
    tail -n 100 "$NH_LOG_FILE" >> "$crash_file"
    
    # Set permissions
    chmod 600 "$crash_file"
    
    nh_log "INFO" "Crash report created at $crash_file"
    
    # Send crash report if webhook is configured
    if [ ! -z "$NH_WEBHOOK_URL" ]; then
        nh_logging_send_remote "$NH_WEBHOOK_URL" "$crash_file" "crash"
    fi
    
    return 0
}

# Log memory usage
nh_logging_memory_usage() {
    if [ ! -f "/proc/meminfo" ]; then
        nh_log "DEBUG" "Memory info not available"
        return 0
    fi
    
    local total_mem=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    local free_mem=$(grep "MemFree" /proc/meminfo | awk '{print $2}')
    local available_mem=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
    
    # Calculate used memory and percentage
    local used_mem=$(($total_mem - $available_mem))
    local used_percent=$(($used_mem * 100 / $total_mem))
    
    nh_log "MEMORY" "Memory usage: ${used_percent}% (${used_mem}K used, ${available_mem}K available, ${total_mem}K total)"
    
    return 0
}

# Log disk usage
nh_logging_disk_usage() {
    local dir=${1:-"$HOME"}
    
    local total=$(df -k "$dir" | awk 'NR==2 {print $2}')
    local used=$(df -k "$dir" | awk 'NR==2 {print $3}')
    local available=$(df -k "$dir" | awk 'NR==2 {print $4}')
    local used_percent=$(df -k "$dir" | awk 'NR==2 {print $5}' | tr -d '%')
    
    nh_log "DISK" "Disk usage for $dir: ${used_percent}% (${used}K used, ${available}K available, ${total}K total)"
    
    return 0
}

# Log network status
nh_logging_network_status() {
    # Check internet connectivity
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        nh_log "NETWORK" "Internet connectivity: Available"
        
        # Check DNS resolution
        if nslookup kali.org >/dev/null 2>&1; then
            nh_log "NETWORK" "DNS resolution: Working"
        else
            nh_log "NETWORK" "DNS resolution: Failed"
        fi
        
        # Check download speed (basic test)
        local start_time=$(date +%s)
        if curl -s -o /dev/null -w "%{speed_download}" "https://kali.download/README" >/dev/null 2>&1; then
            local end_time=$(date +%s)
            local duration=$(($end_time - $start_time))
            if [ $duration -eq 0 ]; then duration=1; fi
            
            nh_log "NETWORK" "Download test: Successful (took ${duration}s)"
        else
            nh_log "NETWORK" "Download test: Failed"
        fi
    else
        nh_log "NETWORK" "Internet connectivity: Not available"
    fi
    
    return 0
}

# Log all environment variables (filtered for security)
nh_logging_environment() {
    nh_log "INFO" "Logging environment variables (filtered)"
    
    # Create a separator in the log
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "ENVIRONMENT VARIABLES (FILTERED)" >> "$NH_LOG_FILE"
    echo "=======================================================" >> "$NH_LOG_FILE"
    
    # Filter out sensitive information
    env | grep -v -E "(PASSWORD|TOKEN|SECRET|KEY)" | sort >> "$NH_LOG_FILE"
    
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "" >> "$NH_LOG_FILE"
    
    return 0
}

# Log installation summary
nh_logging_installation_summary() {
    local status=$1
    local image_type=$2
    local architecture=$3
    local duration=$4
    
    nh_log "INFO" "Logging installation summary"
    
    # Create a separator in the log
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "INSTALLATION SUMMARY" >> "$NH_LOG_FILE"
    echo "=======================================================" >> "$NH_LOG_FILE"
    
    echo "Status: $status" >> "$NH_LOG_FILE"
    echo "Image Type: $image_type" >> "$NH_LOG_FILE"
    echo "Architecture: $architecture" >> "$NH_LOG_FILE"
    echo "Duration: $duration seconds" >> "$NH_LOG_FILE"
    echo "Installation Directory: $NH_INSTALL_DIR" >> "$NH_LOG_FILE"
    echo "Completed: $(date)" >> "$NH_LOG_FILE"
    
    # Log installed files
    echo "Installed Files:" >> "$NH_LOG_FILE"
    ls -la "$NH_INSTALL_DIR" >> "$NH_LOG_FILE"
    
    echo "=======================================================" >> "$NH_LOG_FILE"
    echo "" >> "$NH_LOG_FILE"
    
    # Send installation summary to remote server if configured
    if [ ! -z "$NH_WEBHOOK_URL" ]; then
        nh_logging_send_remote "$NH_WEBHOOK_URL" "$NH_LOG_FILE" "$status"
    fi
    
    return 0
}

# Initialize enhanced logging
nh_logging_init
