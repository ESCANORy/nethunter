#!/data/data/com.termux/files/usr/bin/bash
# utils.sh - Utility functions for NetHunter Installer
# Version: 3.1 (May 2025) - Enhanced URL checking and error handling

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
fi

# ===== Utility Functions =====

# Check available space
nh_check_space() {
    local required_space=$1
    
    nh_log "INFO" "Checking available space"
    
    # Get available space in KB
    local available_space=$(df $HOME | awk 'NR==2 {print $4}')
    local available_mb=$(( available_space / 1024 ))
    
    nh_log "INFO" "Available space: $available_mb MB"
    
    # Convert required space to KB if specified in MB
    if [ "$2" = "MB" ]; then
        required_space=$(( required_space * 1024 ))
    fi
    
    # Check if enough space is available
    if [ $available_space -lt $required_space ]; then
        local required_mb=$(( required_space / 1024 ))
        nh_log "WARNING" "Not enough space. Required: $required_mb MB, Available: $available_mb MB"
        
        if [ "$NH_AUTO_MODE" = "true" ] || [ "$NH_FORCE_MODE" = "true" ]; then
            nh_log "WARNING" "Continuing anyway due to auto/force mode"
            return 0
        else
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                nh_log "ERROR" "Installation aborted due to insufficient space"
                return 1
            fi
        fi
    else
        nh_log "SUCCESS" "Sufficient space available"
    fi
    
    return 0
}

# Check URL exists and is accessible
nh_check_url() {
    local url=$1
    local timeout=${2:-15} # Increased timeout slightly
    
    nh_log "INFO" "Verifying URL accessibility: $url"
    
    # Use curl to check URL status. -L follows redirects.
    # --fail causes curl to return non-zero on server errors (4xx, 5xx).
    # -I gets headers only.
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" --head --fail -L --max-time $timeout "$url")
    local curl_exit_code=$?

    if [ $curl_exit_code -eq 0 ]; then
        nh_log "SUCCESS" "URL is valid and accessible (HTTP Status: $http_status)"
        return 0
    else
        # Provide more specific feedback based on curl exit code
        case $curl_exit_code in
            6) nh_log "WARNING" "URL check failed: Could not resolve host. Check DNS or hostname.";; 
            7) nh_log "WARNING" "URL check failed: Could not connect to host. Check network connection or firewall.";; 
            22) nh_log "WARNING" "URL check failed: HTTP error (e.g., 404 Not Found, 500 Server Error). Status: $http_status";;
            28) nh_log "WARNING" "URL check failed: Operation timed out after $timeout seconds.";; 
            *) nh_log "WARNING" "URL check failed: Unknown error (curl exit code: $curl_exit_code). Status: $http_status";;
        esac
        nh_log "WARNING" "URL is not accessible: $url"
        return 1
    fi
}

# Download file with progress, resume capability, and improved error handling
nh_download_file() {
    local url=$1
    local output_file=$2
    local description=${3:-file}
    
    nh_log "INFO" "Downloading $description from: $url"
    nh_log "INFO" "Saving to: $output_file"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    # Get file size before download for context
    local file_size=$(curl -sI -L "$url" | grep -i "Content-Length" | awk 
'{print $2}' | tr -d '\r')
    if [ ! -z "$file_size" ] && [[ "$file_size" =~ ^[0-9]+$ ]]; then
        local size_mb=$(echo "scale=2; $file_size/1048576" | bc 2>/dev/null || echo "unknown")
        nh_log "INFO" "Expected file size: ~${size_mb} MB"
    else
        nh_log "INFO" "Could not determine expected file size."
    fi
    
    # Download with wget: -c resumes, -O saves to file, --progress shows bar
    # Add timeout and retry options for robustness
    local wget_opts="-c -O \"$output_file\" --tries=3 --timeout=30"
    if [ "$NH_QUIET_MODE" = "true" ]; then
        wget_opts+=" -q"
    else
        # Force progress bar even if output is redirected (useful for logs)
        wget_opts+=" --progress=bar:force"
    fi
    
    # Execute wget command
    eval wget $wget_opts "$url"
    local wget_exit_code=$?
    
    # Check wget exit code for success/failure
    if [ $wget_exit_code -ne 0 ]; then
        nh_log "ERROR" "Download failed (wget exit code: $wget_exit_code)."
        case $wget_exit_code in
            1) nh_log "ERROR" "Generic error code. Check wget output.";; 
            2) nh_log "ERROR" "Parse error—for instance, when parsing command-line options.";; 
            3) nh_log "ERROR" "File I/O error.";; 
            4) nh_log "ERROR" "Network failure (connection refused, DNS error, etc.). Check connection and URL.";; 
            5) nh_log "ERROR" "SSL verification failure.";; 
            6) nh_log "ERROR" "Username/password authentication failure.";; 
            7) nh_log "ERROR" "Protocol errors.";; 
            8) nh_log "ERROR" "Server issued an error response (e.g., 404 Not Found).";; 
            *) nh_log "ERROR" "Unknown wget error.";;
        esac
        # Clean up potentially incomplete file
        [ -f "$output_file" ] && rm -f "$output_file"
        return 1
    fi
    
    # Verify download integrity (basic size check)
    if [ -f "$output_file" ]; then
        local downloaded_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file")
        # Check if size is suspiciously small (e.g., less than 10KB for rootfs)
        if [ "$downloaded_size" -lt 10240 ]; then 
            nh_log "ERROR" "Downloaded file '$output_file' is suspiciously small ($downloaded_size bytes), likely corrupted or incomplete."
            rm -f "$output_file"
            return 1
        # Optional: Compare with expected size if available
        elif [ ! -z "$file_size" ] && [[ "$file_size" =~ ^[0-9]+$ ]] && [ "$downloaded_size" -ne "$file_size" ]; then
             nh_log "WARNING" "Downloaded file size ($downloaded_size bytes) does not match expected size ($file_size bytes). File might be incomplete."
             # Decide whether to fail or just warn based on tolerance
             # return 1 # Uncomment to fail on size mismatch
        fi
        nh_log "SUCCESS" "Download completed successfully."
        return 0
    else
        nh_log "ERROR" "Download failed. Output file '$output_file' not found after wget reported success."
        return 1
    fi
}

# Extract archive with progress
nh_extract_archive() {
    local archive_file=$1
    local extract_dir=$2
    
    nh_log "INFO" "Extracting archive '$archive_file' to '$extract_dir'"
    
    # Create directory if it doesn't exist
    mkdir -p "$extract_dir"
    
    # Determine archive type
    local file_ext="${archive_file##*.}"
    
    # Extract based on file extension
    local extract_cmd=""
    case "$file_ext" in
        "xz")
            extract_cmd="tar -xJf \"$archive_file\" -C \"$extract_dir\""
            if command -v pv >/dev/null 2>&1 && [ "$NH_QUIET_MODE" != "true" ]; then
                 extract_cmd="pv \"$archive_file\" | tar -xJ -C \"$extract_dir\""
            fi
            ;;
        "gz")
             extract_cmd="tar -xzf \"$archive_file\" -C \"$extract_dir\""
             if command -v pv >/dev/null 2>&1 && [ "$NH_QUIET_MODE" != "true" ]; then
                 extract_cmd="pv \"$archive_file\" | tar -xz -C \"$extract_dir\""
             fi
            ;;
        "bz2")
             extract_cmd="tar -xjf \"$archive_file\" -C \"$extract_dir\""
             if command -v pv >/dev/null 2>&1 && [ "$NH_QUIET_MODE" != "true" ]; then
                 extract_cmd="pv \"$archive_file\" | tar -xj -C \"$extract_dir\""
             fi
            ;;
        "zip")
            extract_cmd="unzip -o \"$archive_file\" -d \"$extract_dir\""
            [ "$NH_QUIET_MODE" = "true" ] && extract_cmd="unzip -qqo \"$archive_file\" -d \"$extract_dir\""
            ;;
        *)
            nh_log "ERROR" "Unsupported archive format: $file_ext"
            return 1
            ;;
    esac
    
    nh_log "INFO" "Executing extraction command: $extract_cmd"
    eval $extract_cmd
    local extract_exit_code=$?

    # Check if extraction was successful
    if [ $extract_exit_code -ne 0 ]; then
        nh_log "ERROR" "Extraction failed (exit code: $extract_exit_code)."
        # Consider cleaning up partially extracted files
        # rm -rf "$extract_dir"/* 
        return 1
    else
        nh_log "SUCCESS" "Extraction completed successfully"
        return 0
    fi
}

# Install required packages
nh_install_packages() {
    local packages=("$@")
    
    nh_log "INFO" "Checking and installing required packages: ${packages[*]}"
    
    local missing_packages=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        nh_log "INFO" "All required packages are already installed."
        return 0
    fi

    nh_log "INFO" "Missing packages: ${missing_packages[*]}"
    nh_log "INFO" "Attempting to install missing packages..."

    # Update package lists first
    nh_log "INFO" "Updating package lists (apt update)..."
    if ! sudo apt-get update -y; then 
        nh_log "WARNING" "Failed to update package lists. Check internet connection or apt sources."
        # Optional: Try termux-change-repo if in Termux
        if nh_command_exists termux-change-repo; then
             nh_log "INFO" "Attempting to change Termux repository and retry update..."
             termux-change-repo
             if ! sudo apt-get update -y; then
                 nh_log "ERROR" "Still failed to update package lists. Cannot proceed with package installation."
                 return 1
             fi
        else
             nh_log "ERROR" "Failed to update package lists. Cannot proceed with package installation."
             return 1
        fi
    fi
    
    # Install missing packages
    local install_cmd="sudo apt-get install -y"
    if [ "$NH_QUIET_MODE" = "true" ]; then
        install_cmd+=" -qq"
    fi
    
    if ! $install_cmd "${missing_packages[@]}"; then
        nh_log "ERROR" "Failed to install some required packages: ${missing_packages[*]}"
        nh_log "ERROR" "Please try installing them manually (e.g., 'pkg install proot wget') and rerun the script."
        return 1
    fi
    
    nh_log "SUCCESS" "All required packages installed successfully"
    return 0
}

# Check architecture
nh_check_architecture() {
    nh_log "DEBUG" "Checking device architecture using 'uname -m'"
    
    local arch=$(uname -m)
    
    case $arch in
        aarch64|arm64)
            nh_log "INFO" "Detected architecture: arm64"
            echo "arm64"
            ;;
        armv7l|armv8l|arm)
            nh_log "INFO" "Detected architecture: armhf"
            echo "armhf"
            ;;
        i686|x86)
            nh_log "INFO" "Detected architecture: i386"
            echo "i386"
            ;;
        x86_64|amd64)
            nh_log "INFO" "Detected architecture: amd64"
            echo "amd64"
            ;;
        *)
            nh_log "ERROR" "Unsupported architecture detected: $arch"
            nh_log "ERROR" "Cannot determine a compatible NetHunter image."
            # Return empty or error code? Returning empty for now.
            echo ""
            ;;
    esac
}

# Create backup
nh_create_backup() {
    local source_dir=$1
    local backup_name=${2:-"backup_$(date +%Y%m%d_%H%M%S)"}
    
    nh_log "INFO" "Creating backup of '$source_dir'"
    
    if [ ! -d "$source_dir" ]; then
        nh_log "ERROR" "Source directory does not exist: $source_dir. Cannot create backup."
        return 1
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$NH_BACKUP_DIR"
    
    # Create backup archive
    local backup_file="$NH_BACKUP_DIR/$backup_name.tar.gz"
    nh_log "INFO" "Saving backup to: $backup_file"
    
    # Use tar with gzip compression. Exclude cache/temp dirs if necessary.
    if tar -czf "$backup_file" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"; then
        nh_log "SUCCESS" "Backup created successfully: $backup_file"
        return 0
    else
        nh_log "ERROR" "Failed to create backup archive (tar exit code: $?)."
        # Clean up potentially incomplete backup file
        [ -f "$backup_file" ] && rm -f "$backup_file"
        return 1
    fi
}

# Restore backup
nh_restore_backup() {
    local backup_file=$1
    local target_dir=$2 # This should be the PARENT directory where the backed-up folder will be restored
    
    nh_log "INFO" "Restoring backup from '$backup_file' to '$target_dir'"
    
    if [ ! -f "$backup_file" ]; then
        nh_log "ERROR" "Backup file does not exist: $backup_file. Cannot restore."
        return 1
    fi

    # Ensure target parent directory exists
    mkdir -p "$target_dir"
    
    # Check for existing installation within the target directory before restoring
    # This logic assumes the backup contains a single top-level folder (e.g., 'kali-arm64')
    # A more robust approach might inspect the tar contents first.
    # For now, we rely on the install/uninstall logic to handle existing dirs.

    nh_log "INFO" "Extracting backup archive..."
    if tar -xzf "$backup_file" -C "$target_dir"; then
        nh_log "SUCCESS" "Backup restored successfully to $target_dir"
        # We might need to re-run setup steps like creating aliases/shortcuts after restore
        nh_log "INFO" "You may need to manually run 'nethunter-cli setup' or similar to re-create shortcuts/aliases if needed."
        return 0
    else
        nh_log "ERROR" "Failed to restore backup (tar exit code: $?)."
        # Consider cleanup of partially extracted files
        return 1
    fi
}

# List available backups
nh_list_backups() {
    nh_log "INFO" "Listing available backups in '$NH_BACKUP_DIR'"
    
    if [ ! -d "$NH_BACKUP_DIR" ]; then
        nh_log "INFO" "Backup directory does not exist: $NH_BACKUP_DIR"
        return 1
    fi

    local backups=($(ls -1 "$NH_BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        nh_log "INFO" "No backups found in $NH_BACKUP_DIR"
        return 1
    else
        nh_log "INFO" "Found ${#backups[@]} backups:"
        
        for backup in "${backups[@]}"; do
            local backup_name=$(basename "$backup")
            # Use stat for more reliable date formatting
            local backup_date=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1 || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$backup")
            local backup_size=$(du -h "$backup" | cut -f1)
            
            echo "  - $backup_name ($backup_size, $backup_date)"
        done
        
        return 0
    fi
}

# Send log to remote server (if enabled)
nh_send_log() {
    if [ -z "$NH_WEBHOOK_URL" ]; then
        nh_log "DEBUG" "Log sending disabled (NH_WEBHOOK_URL not set)"
        return 0
    fi
    
    if [ ! -f "$NH_LOG_FILE" ]; then
        nh_log "WARNING" "Log file not found: $NH_LOG_FILE. Cannot send log."
        return 1
    fi

    nh_log "INFO" "Sending log file '$NH_LOG_FILE' to remote server"
    
    # Compress log file
    local compressed_log="$NH_TEMP_DIR/$(basename "$NH_LOG_FILE").gz"
    if gzip -c "$NH_LOG_FILE" > "$compressed_log"; then
        nh_log "DEBUG" "Log file compressed to $compressed_log"
    else
        nh_log "ERROR" "Failed to compress log file."
        return 1
    fi
    
    # Send log file using curl
    if curl -s -S -f -F "log=@$compressed_log" "$NH_WEBHOOK_URL" > /dev/null; then
        nh_log "SUCCESS" "Log sent successfully to $NH_WEBHOOK_URL"
        # Clean up compressed log
        rm -f "$compressed_log"
        return 0
    else
        nh_log "ERROR" "Failed to send log (curl exit code: $?). Check webhook URL and network."
        # Keep compressed log for debugging?
        # rm -f "$compressed_log"
        return 1
    fi
}

# Check if a command exists
nh_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get JSON value (basic fallback)
nh_get_json_value() {
    local json_file=$1
    local key=$2
    local default_value=$3
    
    if [ ! -f "$json_file" ]; then
        echo "$default_value"
        return
    fi

    if nh_command_exists jq; then
        local value=$(jq -r ".$key // \"$default_value\"" "$json_file" 2>/dev/null)
        echo "$value"
    else
        # Basic fallback using grep/sed - may fail on complex structures
        local value=$(grep -o "\"$key\":[^,}]*" "$json_file" 2>/dev/null | sed -E 's/"'$key'"\s*:\s*"?([^,"]*)"?.*$/\1/' | head -n 1)
        if [ -z "$value" ]; then
            echo "$default_value"
        else
            # Trim leading/trailing whitespace which sed might leave
            echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
        fi
    fi
}

# Parse JSON array (basic fallback)
nh_parse_json_array() {
    local json_file=$1
    local array_key=$2

    if [ ! -f "$json_file" ]; then
        return
    fi
    
    if nh_command_exists jq; then
        jq -r ".$array_key[]" "$json_file" 2>/dev/null
    else
        # Basic fallback using grep/sed - very limited
        grep -o "\"$array_key\":\s*\[[^\]]*\]" "$json_file" | 
        sed -E 's/"'$array_key'"\s*:\s*\[\s*(.*)\s*\]/\1/' |
        tr ',' '\n' |
        sed -E 's/\s*"?([^"[:space:]]*)"?\s*/\1/' # Attempt to clean up strings
    fi
}

# Check if running in Termux environment
nh_check_termux() {
    if [[ "$PREFIX" == *"com.termux"* ]]; then
        nh_log "DEBUG" "Termux environment detected."
        return 0
    else
        nh_log "WARNING" "Not running in Termux environment. Some features might not work correctly."
        return 1
    fi
}

# Check if running as root (discouraged in Termux)
nh_check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        nh_log "WARNING" "Running as root is not recommended in Termux."
    fi
}

# Show banner
nh_show_banner() {
    if [ "$NH_QUIET_MODE" != "true" ]; then
        echo -e "${BLUE}=======================================${NC}"
        echo -e "${CYAN} NetHunter CLI Installer - v$NH_VERSION ${NC}"
        echo -e "${BLUE}=======================================${NC}"
    fi
}

# Load configuration from file
nh_load_config() {
    if [ -f "$NH_CONFIG_FILE" ]; then
        nh_log "DEBUG" "Loading configuration from $NH_CONFIG_FILE"
        # Use nh_get_json_value to load settings safely
        NH_DEFAULT_IMAGE_TYPE=$(nh_get_json_value "$NH_CONFIG_FILE" "default_image_type" "full")
        NH_INSTALL_DIR=$(nh_get_json_value "$NH_CONFIG_FILE" "install_dir" "$HOME/nethunter")
        NH_BACKUP_DIR=$(nh_get_json_value "$NH_CONFIG_FILE" "backup_dir" "/sdcard/.manus/nethunter/backup")
        NH_WEBHOOK_URL=$(nh_get_json_value "$NH_CONFIG_FILE" "webhook_url" "")
        # Add other config loading here
    else
        nh_log "DEBUG" "Configuration file not found, using defaults."
    fi
}

# Save configuration to file
nh_save_config() {
    nh_log "DEBUG" "Saving configuration to $NH_CONFIG_FILE"
    mkdir -p "$(dirname "$NH_CONFIG_FILE")"
    # Use jq if available for proper JSON formatting
    if nh_command_exists jq; then
        jq -n \
          --arg dit "$NH_DEFAULT_IMAGE_TYPE" \
          --arg id "$NH_INSTALL_DIR" \
          --arg bd "$NH_BACKUP_DIR" \
          --arg whu "$NH_WEBHOOK_URL" \
          '{default_image_type: $dit, install_dir: $id, backup_dir: $bd, webhook_url: $whu}' \
          > "$NH_CONFIG_FILE"
    else
        # Basic fallback if jq is not available
        cat > "$NH_CONFIG_FILE" << EOF
{
  "default_image_type": "$NH_DEFAULT_IMAGE_TYPE",
  "install_dir": "$NH_INSTALL_DIR",
  "backup_dir": "$NH_BACKUP_DIR",
  "webhook_url": "$NH_WEBHOOK_URL"
}
EOF
    fi
}

# Create default configuration file
nh_create_default_config() {
    if [ ! -f "$NH_CONFIG_FILE" ]; then
        nh_log "INFO" "Creating default configuration file at $NH_CONFIG_FILE"
        nh_save_config # Save current default values
    fi
}

# Log system information
nh_log_system_info() {
    nh_log "DEBUG" "Logging system information"
    nh_log "DEBUG" "Timestamp: $(date)"
    nh_log "DEBUG" "User: $(whoami)"
    nh_log "DEBUG" "Architecture: $(uname -m)"
    nh_log "DEBUG" "OS: $(uname -o)"
    nh_log "DEBUG" "Kernel: $(uname -r)"
    nh_log "DEBUG" "Termux Version: $(termux-info | grep 'TERMUX_VERSION' || echo 'N/A')"
    nh_log "DEBUG" "Android Version: $(getprop ro.build.version.release || echo 'N/A')"
    nh_log "DEBUG" "Device Model: $(getprop ro.product.model || echo 'N/A')"
}

