#!/usr/bin/env bash
# core.sh - Core functions and variables for NetHunter Installer
# Version: 3.0 (May 2025)

# ===== Global Configuration =====
NH_VERSION="3.0"
NH_INSTALL_DIR="${NH_INSTALL_DIR:-$HOME/nethunter}"
NH_CONFIG_DIR="${NH_CONFIG_DIR:-$HOME/.nethunter}"
NH_LOG_DIR="${NH_LOG_DIR:-$NH_CONFIG_DIR/logs}"
NH_CONFIG_FILE="${NH_CONFIG_FILE:-$NH_CONFIG_DIR/config.json}"
NH_TEMP_DIR="${NH_TEMP_DIR:-$NH_CONFIG_DIR/temp}"
NH_CACHE_DIR="${NH_CACHE_DIR:-$NH_CONFIG_DIR/cache}"
NH_BACKUP_DIR="${NH_BACKUP_DIR:-/sdcard/.manus/nethunter/backup}"

# Default settings (can be overridden by config file or CLI flags)
NH_DEFAULT_IMAGE_TYPE="full"
NH_KEEP_ARCHIVE=false
NH_QUIET_MODE=false
NH_VERBOSE_MODE=false
NH_AUTO_MODE=false
NH_FORCE_MODE=false

# ===== Colors =====
if [ "$NH_NO_COLOR" != "true" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    NC=''
fi

# ===== Core Functions =====

# Initialize environment
nh_init() {
    # Create required directories
    mkdir -p "$NH_INSTALL_DIR" "$NH_CONFIG_DIR" "$NH_LOG_DIR" "$NH_TEMP_DIR" "$NH_CACHE_DIR"
    
    # Initialize logging
    NH_LOG_FILE="$NH_LOG_DIR/nethunter_$(date +%Y%m%d_%H%M%S).log"
    
    # Load configuration if exists
    if [ -f "$NH_CONFIG_FILE" ]; then
        nh_load_config
    else
        nh_create_default_config
    fi
    
    # Log system information
    nh_log_system_info
    
    # Check script integrity if enabled
    if [ "$NH_CHECK_INTEGRITY" = "true" ]; then
        nh_check_integrity
    fi
}

# Log message to file and stdout
nh_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Format log message
    local log_message="[$timestamp] [$level] $message"
    
    # Write to log file
    echo "$log_message" >> "$NH_LOG_FILE"
    
    # Display to stdout based on verbosity settings
    case "$level" in
        "ERROR")
            [ "$NH_QUIET_MODE" != "true" ] && echo -e "${RED}[!] $message${NC}" ;;
        "WARNING")
            [ "$NH_QUIET_MODE" != "true" ] && echo -e "${YELLOW}[*] $message${NC}" ;;
        "INFO")
            [ "$NH_QUIET_MODE" != "true" ] && echo -e "${BLUE}[*] $message${NC}" ;;
        "SUCCESS")
            [ "$NH_QUIET_MODE" != "true" ] && echo -e "${GREEN}[✓] $message${NC}" ;;
        "DEBUG")
            [ "$NH_VERBOSE_MODE" = "true" ] && echo -e "${PURPLE}[D] $message${NC}" ;;
        *)
            [ "$NH_QUIET_MODE" != "true" ] && echo -e "${CYAN}[$level] $message${NC}" ;;
    esac
}

# Log system information
nh_log_system_info() {
    nh_log "INFO" "NetHunter Installer v$NH_VERSION starting"
    nh_log "DEBUG" "Device: $(uname -a)"
    nh_log "DEBUG" "Date: $(date)"
    
    # Log Termux version if available
    if [ -f "$PREFIX/etc/termux-version" ]; then
        nh_log "DEBUG" "Termux version: $(cat $PREFIX/etc/termux-version)"
    fi
    
    # Log Android version if available
    if [ -f "/system/build.prop" ]; then
        android_version=$(grep "ro.build.version.release" /system/build.prop | cut -d'=' -f2)
        nh_log "DEBUG" "Android version: $android_version"
    fi
    
    # Log storage information
    nh_log "DEBUG" "Storage: $(df -h $HOME | awk 'NR==2 {print $2" total, "$4" available"}')"
}

# Check script integrity
nh_check_integrity() {
    nh_log "INFO" "Checking script integrity"
    
    if [ "$NH_SCRIPT_HASH" != "SELF_HASH_PLACEHOLDER" ]; then
        CURRENT_HASH=$(sha256sum "$0" | awk '{print $1}')
        if [ "$CURRENT_HASH" != "$NH_SCRIPT_HASH" ]; then
            nh_log "WARNING" "Script integrity check failed!"
            nh_log "WARNING" "The script may have been modified or tampered with."
            
            if [ "$NH_FORCE_MODE" != "true" ]; then
                read -p "Continue anyway? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    nh_log "ERROR" "Installation aborted due to integrity check failure."
                    exit 1
                fi
            fi
        else
            nh_log "SUCCESS" "Script integrity verified."
        fi
    else
        nh_log "DEBUG" "Integrity check skipped (development mode)."
    fi
}

# Load configuration from file
nh_load_config() {
    nh_log "INFO" "Loading configuration from $NH_CONFIG_FILE"
    
    # Check if jq is installed
    if command -v jq >/dev/null 2>&1; then
        # Parse JSON config with jq
        NH_INSTALL_DIR=$(jq -r '.install_dir // "'"$NH_INSTALL_DIR"'"' "$NH_CONFIG_FILE")
        NH_DEFAULT_IMAGE_TYPE=$(jq -r '.default_image_type // "'"$NH_DEFAULT_IMAGE_TYPE"'"' "$NH_CONFIG_FILE")
        NH_KEEP_ARCHIVE=$(jq -r '.keep_archive // false' "$NH_CONFIG_FILE")
        NH_CHECK_INTEGRITY=$(jq -r '.check_integrity // false' "$NH_CONFIG_FILE")
        NH_SCRIPT_HASH=$(jq -r '.script_hash // "SELF_HASH_PLACEHOLDER"' "$NH_CONFIG_FILE")
    else
        # Fallback to basic parsing if jq is not available
        nh_log "WARNING" "jq not found, using basic config parsing"
        source "$NH_CONFIG_FILE"
    fi
}

# Create default configuration
nh_create_default_config() {
    nh_log "INFO" "Creating default configuration"
    
    # Check if jq is installed
    if command -v jq >/dev/null 2>&1; then
        # Create JSON config with jq
        jq -n \
            --arg install_dir "$NH_INSTALL_DIR" \
            --arg default_image_type "$NH_DEFAULT_IMAGE_TYPE" \
            --argjson keep_archive $NH_KEEP_ARCHIVE \
            --argjson check_integrity false \
            --arg script_hash "SELF_HASH_PLACEHOLDER" \
            --arg created_at "$(date)" \
            '{
                install_dir: $install_dir,
                default_image_type: $default_image_type,
                keep_archive: $keep_archive,
                check_integrity: $check_integrity,
                script_hash: $script_hash,
                created_at: $created_at
            }' > "$NH_CONFIG_FILE"
    else
        # Fallback to basic config if jq is not available
        cat > "$NH_CONFIG_FILE" << EOF
#!/usr/bin/env bash
# NetHunter Configuration
# Created: $(date)

NH_INSTALL_DIR="$NH_INSTALL_DIR"
NH_DEFAULT_IMAGE_TYPE="$NH_DEFAULT_IMAGE_TYPE"
NH_KEEP_ARCHIVE=$NH_KEEP_ARCHIVE
NH_CHECK_INTEGRITY=false
NH_SCRIPT_HASH="SELF_HASH_PLACEHOLDER"
EOF
    fi
    
    nh_log "SUCCESS" "Default configuration created at $NH_CONFIG_FILE"
}

# Save configuration
nh_save_config() {
    nh_log "INFO" "Saving configuration"
    
    # Check if jq is installed
    if command -v jq >/dev/null 2>&1; then
        # Create JSON config with jq
        jq -n \
            --arg install_dir "$NH_INSTALL_DIR" \
            --arg default_image_type "$NH_DEFAULT_IMAGE_TYPE" \
            --argjson keep_archive $NH_KEEP_ARCHIVE \
            --argjson check_integrity $NH_CHECK_INTEGRITY \
            --arg script_hash "$NH_SCRIPT_HASH" \
            --arg updated_at "$(date)" \
            '{
                install_dir: $install_dir,
                default_image_type: $default_image_type,
                keep_archive: $keep_archive,
                check_integrity: $check_integrity,
                script_hash: $script_hash,
                updated_at: $updated_at
            }' > "$NH_CONFIG_FILE"
    else
        # Fallback to basic config if jq is not available
        cat > "$NH_CONFIG_FILE" << EOF
#!/usr/bin/env bash
# NetHunter Configuration
# Updated: $(date)

NH_INSTALL_DIR="$NH_INSTALL_DIR"
NH_DEFAULT_IMAGE_TYPE="$NH_DEFAULT_IMAGE_TYPE"
NH_KEEP_ARCHIVE=$NH_KEEP_ARCHIVE
NH_CHECK_INTEGRITY=$NH_CHECK_INTEGRITY
NH_SCRIPT_HASH="$NH_SCRIPT_HASH"
EOF
    fi
    
    nh_log "SUCCESS" "Configuration saved to $NH_CONFIG_FILE"
}

# Check if running as root (which should be avoided)
nh_check_root() {
    nh_log "DEBUG" "Checking for root privileges"
    
    if [ "$(id -u)" = "0" ]; then
        nh_log "ERROR" "This script should not be run as root"
        nh_log "ERROR" "Please run it as a regular user in Termux"
        exit 1
    fi
    
    nh_log "DEBUG" "Not running as root, continuing"
}

# Check if running in Termux
nh_check_termux() {
    nh_log "DEBUG" "Checking if running in Termux"
    
    if [ ! -d "/data/data/com.termux" ]; then
        nh_log "ERROR" "This script must be run in Termux"
        exit 1
    fi
    
    nh_log "DEBUG" "Running in Termux, continuing"
}

# Show banner
nh_show_banner() {
    if [ "$NH_QUIET_MODE" != "true" ]; then
        clear
        echo -e "${BLUE}#########################################${NC}"
        echo -e "${BLUE}##                                     ##${NC}"
        echo -e "${BLUE}##  ${RED}NetHunter for Termux Installer${BLUE}    ##${NC}"
        echo -e "${BLUE}##  ${YELLOW}Version $NH_VERSION - Advanced Edition${BLUE}  ##${NC}"
        echo -e "${BLUE}##                                     ##${NC}"
        echo -e "${BLUE}#########################################${NC}"
        echo ""
    fi
}

# Clean up on exit
nh_cleanup() {
    nh_log "INFO" "Cleaning up temporary files"
    
    # Remove temporary files
    if [ -d "$NH_TEMP_DIR" ]; then
        rm -rf "$NH_TEMP_DIR"/*
    fi
    
    nh_log "INFO" "Cleanup complete"
}

# Set up trap for cleanup on exit
trap nh_cleanup EXIT
