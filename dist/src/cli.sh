#!/data/data/com.termux/files/usr/bin/bash
# cli.sh - Command-line interface functions for NetHunter Installer
# Version: 3.0 (May 2025)

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
    source "$SCRIPT_DIR/utils.sh"
    source "$SCRIPT_DIR/install.sh"
    source "$SCRIPT_DIR/gpg.sh"
fi

# ===== CLI Functions =====

# Show help message
nh_show_help() {
    echo "NetHunter CLI - Version $NH_VERSION"
    echo "Usage: nethunter-cli [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install    Install NetHunter"
    echo "  update     Update existing NetHunter installation"
    echo "  uninstall  Remove NetHunter"
    echo "  backup     Create backup of NetHunter"
    echo "  restore    Restore NetHunter from backup"
    echo "  verify     Verify NetHunter installation"
    echo "  help       Show this help message"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE       Image type (full, minimal, nano)"
    echo "  -a, --arch ARCH       Architecture (arm64, armhf, amd64, i386)"
    echo "  -d, --dir DIR         Installation directory"
    echo "  -k, --keep-archive    Keep downloaded archive after installation"
    echo "  -f, --force           Force operation without confirmation"
    echo "  -q, --quiet           Quiet mode (minimal output)"
    echo "  -v, --verbose         Verbose mode (detailed output)"
    echo "  -y, --yes             Automatic yes to prompts (non-interactive)"
    echo "  --dev                 Development mode (skip integrity checks)"
    echo "  --no-color            Disable colored output"
    echo ""
    echo "Examples:"
    echo "  nethunter-cli install"
    echo "  nethunter-cli install --type minimal --arch arm64"
    echo "  nethunter-cli update --keep-archive"
    echo "  nethunter-cli uninstall --force"
    echo ""
}

# Parse command-line arguments
nh_parse_args() {
    # Default values
    NH_COMMAND=""
    NH_IMAGE_TYPE="$NH_DEFAULT_IMAGE_TYPE"
    NH_ARCHITECTURE=""
    NH_KEEP_ARCHIVE=false
    NH_FORCE_MODE=false
    NH_QUIET_MODE=false
    NH_VERBOSE_MODE=false
    NH_AUTO_MODE=false
    NH_DEV_MODE=false
    NH_NO_COLOR=false
    
    # No arguments provided
    if [ $# -eq 0 ]; then
        nh_show_help
        return 1
    fi
    
    # First argument is the command
    NH_COMMAND="$1"
    shift
    
    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            -t|--type)
                NH_IMAGE_TYPE="$2"
                shift 2
                ;;
            --type=*)
                NH_IMAGE_TYPE="${1#*=}"
                shift
                ;;
            -a|--arch)
                NH_ARCHITECTURE="$2"
                shift 2
                ;;
            --arch=*)
                NH_ARCHITECTURE="${1#*=}"
                shift
                ;;
            -d|--dir)
                NH_INSTALL_DIR="$2"
                shift 2
                ;;
            --dir=*)
                NH_INSTALL_DIR="${1#*=}"
                shift
                ;;
            -k|--keep-archive)
                NH_KEEP_ARCHIVE=true
                shift
                ;;
            -f|--force)
                NH_FORCE_MODE=true
                shift
                ;;
            -q|--quiet)
                NH_QUIET_MODE=true
                shift
                ;;
            -v|--verbose)
                NH_VERBOSE_MODE=true
                shift
                ;;
            -y|--yes)
                NH_AUTO_MODE=true
                shift
                ;;
            --dev)
                NH_DEV_MODE=true
                shift
                ;;
            --no-color)
                NH_NO_COLOR=true
                # Reset color variables
                RED=''
                GREEN=''
                YELLOW=''
                BLUE=''
                PURPLE=''
                CYAN=''
                NC=''
                shift
                ;;
            -h|--help)
                nh_show_help
                return 1
                ;;
            *)
                nh_log "ERROR" "Unknown option: $1"
                nh_show_help
                return 1
                ;;
        esac
    done
    
    # Validate command
    case "$NH_COMMAND" in
        install|update|uninstall|backup|restore|verify|help)
            # Valid command
            ;;
        "")
            nh_log "ERROR" "No command specified"
            nh_show_help
            return 1
            ;;
        *)
            nh_log "ERROR" "Unknown command: $NH_COMMAND"
            nh_show_help
            return 1
            ;;
    esac
    
    # Validate image type
    case "$NH_IMAGE_TYPE" in
        full|minimal|nano)
            # Valid image type
            ;;
        *)
            nh_log "ERROR" "Invalid image type: $NH_IMAGE_TYPE"
            nh_log "ERROR" "Valid types are: full, minimal, nano"
            return 1
            ;;
    esac
    
    # Validate architecture if specified
    if [ ! -z "$NH_ARCHITECTURE" ]; then
        case "$NH_ARCHITECTURE" in
            arm64|armhf|amd64|i386)
                # Valid architecture
                ;;
            *)
                nh_log "ERROR" "Invalid architecture: $NH_ARCHITECTURE"
                nh_log "ERROR" "Valid architectures are: arm64, armhf, amd64, i386"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# Execute command
nh_execute_command() {
    # If no architecture specified, detect it
    if [ -z "$NH_ARCHITECTURE" ]; then
        NH_ARCHITECTURE=$(nh_check_architecture)
    fi
    
    # Execute command
    case "$NH_COMMAND" in
        install)
            nh_install "$NH_IMAGE_TYPE" "$NH_ARCHITECTURE"
            ;;
        update)
            nh_update "$NH_IMAGE_TYPE" "$NH_ARCHITECTURE"
            ;;
        uninstall)
            nh_uninstall
            ;;
        backup)
            local backup_name="nethunter_backup_$(date +%Y%m%d_%H%M%S)"
            nh_create_backup "$NH_INSTALL_DIR" "$backup_name"
            ;;
        restore)
            # Find latest backup if not specified
            local backup_file=""
            if [ -d "$NH_BACKUP_DIR" ]; then
                backup_file=$(ls -t "$NH_BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1)
            fi
            
            if [ -z "$backup_file" ]; then
                nh_log "ERROR" "No backup files found"
                return 1
            fi
            
            nh_restore_backup "$backup_file" "$NH_INSTALL_DIR"
            ;;
        verify)
            # Verify installation
            if [ ! -d "$NH_INSTALL_DIR/kali-$NH_ARCHITECTURE" ]; then
                nh_log "ERROR" "NetHunter installation not found"
                return 1
            fi
            
            if [ ! -f "$NH_INSTALL_DIR/start-nethunter.sh" ]; then
                nh_log "ERROR" "NetHunter launch script not found"
                return 1
            fi
            
            nh_log "SUCCESS" "NetHunter installation verified"
            ;;
        help)
            nh_show_help
            ;;
    esac
    
    return $?
}

# Main CLI function
nh_cli_main() {
    # Initialize environment
    nh_init
    
    # Show banner
    nh_show_banner
    
    # Parse arguments
    if ! nh_parse_args "$@"; then
        return 1
    fi
    
    # Check if running as root
    nh_check_root
    
    # Check if running in Termux
    nh_check_termux
    
    # Initialize GPG if needed
    if [ "$NH_COMMAND" != "help" ]; then
        nh_gpg_init
        nh_gpg_create_default_key
    fi
    
    # Execute command
    nh_execute_command
    
    return $?
}
