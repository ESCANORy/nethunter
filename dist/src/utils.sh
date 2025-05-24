#!/data/data/com.termux/files/usr/bin/bash
# utils.sh - Utility functions for NetHunter Installer
# Version: 3.0 (May 2025)

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

# Check URL exists
nh_check_url() {
    local url=$1
    local timeout=${2:-10}
    
    nh_log "INFO" "Verifying URL: $url"
    
    # Check if URL exists with timeout
    if curl -s --head --fail --max-time $timeout "$url" > /dev/null; then
        nh_log "SUCCESS" "URL is valid"
        return 0
    else
        nh_log "WARNING" "URL is not accessible: $url"
        return 1
    fi
}

# Download file with progress and resume capability
nh_download_file() {
    local url=$1
    local output_file=$2
    local description=${3:-file}
    
    nh_log "INFO" "Downloading $description from: $url"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output_file")"
    
    # Get file size before download
    local file_size=$(curl -sI "$url" | grep -i "Content-Length" | awk '{print $2}' | tr -d '\r')
    if [ ! -z "$file_size" ]; then
        local size_mb=$(echo "scale=2; $file_size/1048576" | bc 2>/dev/null || echo "unknown")
        nh_log "INFO" "File size: ~${size_mb} MB"
    fi
    
    # Download with progress and resume capability
    if [ "$NH_QUIET_MODE" = "true" ]; then
        wget -q -c -O "$output_file" "$url"
    else
        wget -c --progress=bar:force -O "$output_file" "$url"
    fi
    
    # Check if download was successful
    if [ $? -ne 0 ]; then
        nh_log "ERROR" "Download failed"
        return 1
    fi
    
    # Verify download integrity
    if [ -f "$output_file" ]; then
        local downloaded_size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file")
        if [ "$downloaded_size" -lt 10000 ]; then
            nh_log "ERROR" "Downloaded file is too small, likely corrupted"
            rm -f "$output_file"
            return 1
        else
            nh_log "SUCCESS" "Download completed successfully"
            return 0
        fi
    else
        nh_log "ERROR" "Download failed. File not found"
        return 1
    fi
}

# Extract archive with progress
nh_extract_archive() {
    local archive_file=$1
    local extract_dir=$2
    
    nh_log "INFO" "Extracting archive to $extract_dir"
    
    # Create directory if it doesn't exist
    mkdir -p "$extract_dir"
    
    # Determine archive type
    local file_ext="${archive_file##*.}"
    
    # Extract based on file extension
    case "$file_ext" in
        "xz")
            if command -v pv >/dev/null 2>&1; then
                nh_log "INFO" "Extracting with progress..."
                pv "$archive_file" | tar -xJ -C "$extract_dir"
            else
                nh_log "INFO" "Extracting (pv not available)..."
                tar -xJf "$archive_file" -C "$extract_dir"
            fi
            ;;
        "gz")
            if command -v pv >/dev/null 2>&1; then
                pv "$archive_file" | tar -xz -C "$extract_dir"
            else
                tar -xzf "$archive_file" -C "$extract_dir"
            fi
            ;;
        "bz2")
            if command -v pv >/dev/null 2>&1; then
                pv "$archive_file" | tar -xj -C "$extract_dir"
            else
                tar -xjf "$archive_file" -C "$extract_dir"
            fi
            ;;
        "zip")
            unzip -q "$archive_file" -d "$extract_dir"
            ;;
        *)
            nh_log "ERROR" "Unsupported archive format: $file_ext"
            return 1
            ;;
    esac
    
    # Check if extraction was successful
    if [ $? -ne 0 ]; then
        nh_log "ERROR" "Extraction failed"
        return 1
    else
        nh_log "SUCCESS" "Extraction completed successfully"
        return 0
    fi
}

# Install required packages
nh_install_packages() {
    local packages=("$@")
    
    nh_log "INFO" "Installing required packages: ${packages[*]}"
    
    # Update package lists
    pkg update -y || {
        nh_log "WARNING" "Failed to update package lists. Trying alternative mirrors..."
        termux-change-repo
        pkg update -y || {
            nh_log "ERROR" "Still failed to update. Please check your internet connection"
            return 1
        }
    }
    
    # Install all packages at once
    if [ "$NH_QUIET_MODE" = "true" ]; then
        pkg install -y "${packages[@]}" > /dev/null 2>&1
    else
        pkg install -y "${packages[@]}"
    fi
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
        nh_log "WARNING" "Failed to install some packages. Trying individually..."
        
        # Try installing packages individually
        local failed=0
        for pkg in "${packages[@]}"; do
            nh_log "INFO" "Installing $pkg..."
            if [ "$NH_QUIET_MODE" = "true" ]; then
                pkg install -y "$pkg" > /dev/null 2>&1
            else
                pkg install -y "$pkg"
            fi
            
            if [ $? -ne 0 ]; then
                nh_log "ERROR" "Failed to install $pkg"
                failed=1
            else
                nh_log "SUCCESS" "Installed $pkg"
            fi
        done
        
        if [ $failed -eq 1 ]; then
            nh_log "WARNING" "Some packages failed to install"
            return 1
        fi
    fi
    
    nh_log "SUCCESS" "All packages installed successfully"
    return 0
}

# Check architecture
nh_check_architecture() {
    nh_log "INFO" "Checking device architecture"
    
    local arch=$(uname -m)
    
    case $arch in
        aarch64|arm64)
            nh_log "SUCCESS" "ARM64 architecture detected"
            echo "arm64"
            ;;
        armv7l|armv8l|arm)
            nh_log "SUCCESS" "ARMHF architecture detected"
            echo "armhf"
            ;;
        i686|x86)
            nh_log "SUCCESS" "i386 architecture detected"
            echo "i386"
            ;;
        x86_64|amd64)
            nh_log "SUCCESS" "AMD64 architecture detected"
            echo "amd64"
            ;;
        *)
            nh_log "WARNING" "Unsupported architecture: $arch"
            nh_log "WARNING" "Trying with ARM64 as fallback"
            echo "arm64"
            ;;
    esac
}

# Create backup
nh_create_backup() {
    local source_dir=$1
    local backup_name=${2:-"backup_$(date +%Y%m%d_%H%M%S)"}
    
    nh_log "INFO" "Creating backup of $source_dir"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$NH_BACKUP_DIR"
    
    # Create backup archive
    local backup_file="$NH_BACKUP_DIR/$backup_name.tar.gz"
    
    if [ -d "$source_dir" ]; then
        tar -czf "$backup_file" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
        
        if [ $? -eq 0 ]; then
            nh_log "SUCCESS" "Backup created at $backup_file"
            return 0
        else
            nh_log "ERROR" "Failed to create backup"
            return 1
        fi
    else
        nh_log "ERROR" "Source directory does not exist: $source_dir"
        return 1
    fi
}

# Restore backup
nh_restore_backup() {
    local backup_file=$1
    local target_dir=$2
    
    nh_log "INFO" "Restoring backup from $backup_file"
    
    if [ -f "$backup_file" ]; then
        # Create target directory if it doesn't exist
        mkdir -p "$(dirname "$target_dir")"
        
        # Remove existing target if it exists
        if [ -d "$target_dir" ]; then
            nh_log "INFO" "Removing existing target directory"
            rm -rf "$target_dir"
        fi
        
        # Extract backup
        tar -xzf "$backup_file" -C "$(dirname "$target_dir")"
        
        if [ $? -eq 0 ]; then
            nh_log "SUCCESS" "Backup restored to $target_dir"
            return 0
        else
            nh_log "ERROR" "Failed to restore backup"
            return 1
        fi
    else
        nh_log "ERROR" "Backup file does not exist: $backup_file"
        return 1
    fi
}

# List available backups
nh_list_backups() {
    nh_log "INFO" "Listing available backups"
    
    if [ -d "$NH_BACKUP_DIR" ]; then
        local backups=($(ls -1 "$NH_BACKUP_DIR"/*.tar.gz 2>/dev/null))
        
        if [ ${#backups[@]} -eq 0 ]; then
            nh_log "INFO" "No backups found"
            return 1
        else
            nh_log "INFO" "Found ${#backups[@]} backups:"
            
            for backup in "${backups[@]}"; do
                local backup_name=$(basename "$backup")
                local backup_date=$(stat -c %y "$backup" 2>/dev/null || stat -f "%Sm" "$backup")
                local backup_size=$(du -h "$backup" | cut -f1)
                
                echo "  - $backup_name ($backup_size, $backup_date)"
            done
            
            return 0
        fi
    else
        nh_log "INFO" "Backup directory does not exist"
        return 1
    fi
}

# Send log to remote server (if enabled)
nh_send_log() {
    if [ -z "$NH_WEBHOOK_URL" ]; then
        nh_log "DEBUG" "Log sending disabled (no webhook URL)"
        return 0
    fi
    
    nh_log "INFO" "Sending log to remote server"
    
    # Compress log file
    local compressed_log="$NH_TEMP_DIR/$(basename "$NH_LOG_FILE").gz"
    gzip -c "$NH_LOG_FILE" > "$compressed_log"
    
    # Send log file
    curl -s -F "log=@$compressed_log" "$NH_WEBHOOK_URL" > /dev/null
    
    if [ $? -eq 0 ]; then
        nh_log "SUCCESS" "Log sent successfully"
        return 0
    else
        nh_log "ERROR" "Failed to send log"
        return 1
    fi
}

# Check if a command exists
nh_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get JSON value (with or without jq)
nh_get_json_value() {
    local json_file=$1
    local key=$2
    local default_value=$3
    
    if nh_command_exists jq; then
        local value=$(jq -r ".$key // \"$default_value\"" "$json_file" 2>/dev/null)
        echo "$value"
    else
        # Fallback to grep/sed if jq is not available
        local value=$(grep -o "\"$key\":[^,}]*" "$json_file" 2>/dev/null | sed -E 's/"'"$key"'"\s*:\s*"?([^,"]*)"?.*/\1/')
        if [ -z "$value" ]; then
            echo "$default_value"
        else
            echo "$value"
        fi
    fi
}

# Parse JSON array (with or without jq)
nh_parse_json_array() {
    local json_file=$1
    local array_key=$2
    
    if nh_command_exists jq; then
        jq -r ".$array_key[]" "$json_file" 2>/dev/null
    else
        # This is a very basic fallback and might not work for complex JSON
        grep -o "\"$array_key\":\s*\[\s*[^]]*\]" "$json_file" | 
        sed -E 's/"'"$array_key"'"\s*:\s*\[\s*(.*)\s*\]/\1/' |
        tr ',' '\n' |
        sed -E 's/\s*"([^"]*)"?\s*/\1/'
    fi
}
