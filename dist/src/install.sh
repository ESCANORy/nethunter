#!/data/data/com.termux/files/usr/bin/bash
# install.sh - Installation functions for NetHunter Installer
# Version: 3.0 (May 2025)

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
    source "$SCRIPT_DIR/utils.sh"
fi

# ===== Installation Functions =====

# Fetch available image list from server
nh_fetch_image_list() {
    nh_log "INFO" "Fetching available image list"
    
    local index_url="https://kali.download/nethunter-images/current/rootfs/index.json"
    local index_file="$NH_CACHE_DIR/image_index.json"
    
    # Download index file
    if ! nh_download_file "$index_url" "$index_file" "image index"; then
        # If JSON index doesn't exist, try to parse directory listing
        nh_log "WARNING" "Could not fetch image index, falling back to directory listing"
        
        # Create a basic JSON structure
        cat > "$index_file" << EOF
{
  "images": [
    {"type": "full", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-arm64.tar.xz"},
    {"type": "minimal", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-arm64.tar.xz"},
    {"type": "nano", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-nano-arm64.tar.xz"},
    {"type": "full", "arch": "armhf", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-armhf.tar.xz"},
    {"type": "minimal", "arch": "armhf", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-armhf.tar.xz"},
    {"type": "nano", "arch": "armhf", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-nano-armhf.tar.xz"},
    {"type": "full", "arch": "amd64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-amd64.tar.xz"},
    {"type": "minimal", "arch": "amd64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-amd64.tar.xz"},
    {"type": "nano", "arch": "amd64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-nano-amd64.tar.xz"},
    {"type": "full", "arch": "i386", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-i386.tar.xz"},
    {"type": "minimal", "arch": "i386", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-i386.tar.xz"},
    {"type": "nano", "arch": "i386", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-nano-i386.tar.xz"}
  ]
}
EOF
    fi
    
    # Verify the index file exists and is valid JSON
    if [ ! -f "$index_file" ] || ! nh_command_exists jq || ! jq empty "$index_file" 2>/dev/null; then
        nh_log "ERROR" "Invalid image index file"
        return 1
    fi
    
    nh_log "SUCCESS" "Image list fetched successfully"
    return 0
}

# Get image URL based on type and architecture
nh_get_image_url() {
    local image_type=$1
    local architecture=$2
    local index_file="$NH_CACHE_DIR/image_index.json"
    
    nh_log "INFO" "Looking for image: type=$image_type, arch=$architecture"
    
    # Ensure we have the image list
    if [ ! -f "$index_file" ]; then
        nh_fetch_image_list || return 1
    fi
    
    # Try to find the exact match
    local image_url=""
    
    if nh_command_exists jq; then
        image_url=$(jq -r ".images[] | select(.type == \"$image_type\" and .arch == \"$architecture\") | .url" "$index_file" 2>/dev/null | head -n 1)
    else
        # Fallback to grep if jq is not available
        image_url=$(grep -o "\"url\":.*$image_type.*$architecture.*\.tar\.xz" "$index_file" | head -n 1 | sed -E 's/.*"url":\s*"([^"]+)".*/\1/')
    fi
    
    # If not found, try alternatives
    if [ -z "$image_url" ]; then
        nh_log "WARNING" "Image not found, trying alternatives"
        
        # Try other image types
        for alt_type in "full" "minimal" "nano"; do
            if [ "$alt_type" != "$image_type" ]; then
                if nh_command_exists jq; then
                    image_url=$(jq -r ".images[] | select(.type == \"$alt_type\" and .arch == \"$architecture\") | .url" "$index_file" 2>/dev/null | head -n 1)
                else
                    image_url=$(grep -o "\"url\":.*$alt_type.*$architecture.*\.tar\.xz" "$index_file" | head -n 1 | sed -E 's/.*"url":\s*"([^"]+)".*/\1/')
                fi
                
                if [ ! -z "$image_url" ]; then
                    nh_log "INFO" "Found alternative type: $alt_type"
                    break
                fi
            fi
        done
        
        # If still not found, try other architectures
        if [ -z "$image_url" ]; then
            for alt_arch in "arm64" "armhf" "amd64" "i386"; do
                if [ "$alt_arch" != "$architecture" ]; then
                    if nh_command_exists jq; then
                        image_url=$(jq -r ".images[] | select(.type == \"$image_type\" and .arch == \"$alt_arch\") | .url" "$index_file" 2>/dev/null | head -n 1)
                    else
                        image_url=$(grep -o "\"url\":.*$image_type.*$alt_arch.*\.tar\.xz" "$index_file" | head -n 1 | sed -E 's/.*"url":\s*"([^"]+)".*/\1/')
                    fi
                    
                    if [ ! -z "$image_url" ]; then
                        nh_log "INFO" "Found alternative architecture: $alt_arch"
                        break
                    fi
                fi
            done
        fi
    fi
    
    # If still not found, use hardcoded URL as last resort
    if [ -z "$image_url" ]; then
        nh_log "WARNING" "No suitable image found in index, using hardcoded URL"
        image_url="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-$image_type-$architecture.tar.xz"
    fi
    
    # Verify the URL is accessible
    if nh_check_url "$image_url"; then
        echo "$image_url"
        return 0
    else
        nh_log "ERROR" "Image URL is not accessible: $image_url"
        return 1
    fi
}

# Download and extract rootfs
nh_download_rootfs() {
    local image_type=$1
    local architecture=$2
    
    nh_log "INFO" "Preparing to download rootfs"
    
    # Get image URL
    local image_url=$(nh_get_image_url "$image_type" "$architecture")
    if [ -z "$image_url" ]; then
        nh_log "ERROR" "Failed to get image URL"
        return 1
    fi
    
    nh_log "INFO" "Using image URL: $image_url"
    
    # Determine required space based on image type
    local required_space=0
    case "$image_type" in
        "full")
            required_space=3000000 # 3GB in KB
            ;;
        "minimal")
            required_space=500000 # 500MB in KB
            ;;
        "nano")
            required_space=500000 # 500MB in KB
            ;;
        *)
            required_space=3000000 # Default to 3GB
            ;;
    esac
    
    # Check if we have enough space
    if ! nh_check_space $required_space; then
        return 1
    fi
    
    # Download rootfs
    local rootfs_file="$NH_CACHE_DIR/kalifs-$architecture.tar.xz"
    if ! nh_download_file "$image_url" "$rootfs_file" "rootfs"; then
        return 1
    fi
    
    # Extract rootfs
    local extract_dir="$NH_INSTALL_DIR/kali-$architecture"
    if ! nh_extract_archive "$rootfs_file" "$extract_dir"; then
        return 1
    fi
    
    # Clean up if not keeping archive
    if [ "$NH_KEEP_ARCHIVE" != "true" ]; then
        nh_log "INFO" "Removing downloaded archive"
        rm -f "$rootfs_file"
    else
        nh_log "INFO" "Keeping downloaded archive at $rootfs_file"
    fi
    
    return 0
}

# Create launch script
nh_create_launch_script() {
    local architecture=$1
    
    nh_log "INFO" "Creating launch script"
    
    local launch_script="$NH_INSTALL_DIR/start-nethunter.sh"
    
    cat > "$launch_script" << 'EOL'
#!/data/data/com.termux/files/usr/bin/bash
cd $(dirname $0)
## Start NetHunter
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r kali-$1"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b /data"
command+=" -b /vendor"
command+=" -b /system"
command+=" -b kali-$1/root:/dev/shm"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="$2 $3 $4 $5 $6 $7 $8 $9"
if [ -z "$2" ]; then
    exec $command
else
    $command -c "$com"
fi
EOL
    
    chmod 700 "$launch_script"
    
    nh_log "SUCCESS" "Launch script created at $launch_script"
    return 0
}

# Create desktop shortcut
nh_create_desktop_shortcut() {
    local architecture=$1
    
    nh_log "INFO" "Creating desktop shortcut"
    
    mkdir -p "$HOME/.shortcuts"
    
    local shortcut_file="$HOME/.shortcuts/NetHunter"
    
    cat > "$shortcut_file" << EOF
#!/data/data/com.termux/files/usr/bin/bash
cd $NH_INSTALL_DIR && ./start-nethunter.sh $architecture
EOF
    
    chmod 700 "$shortcut_file"
    
    nh_log "SUCCESS" "Desktop shortcut created at $shortcut_file"
    return 0
}

# Create aliases
nh_create_aliases() {
    local architecture=$1
    
    nh_log "INFO" "Creating aliases"
    
    # Check if aliases already exist
    if grep -q "alias nethunter=" "$HOME/.bashrc"; then
        nh_log "INFO" "Updating existing aliases"
        sed -i '/alias nethunter=/d' "$HOME/.bashrc"
        sed -i '/alias nh=/d' "$HOME/.bashrc"
    fi
    
    # Add new aliases
    echo "alias nethunter='$NH_INSTALL_DIR/start-nethunter.sh $architecture'" >> "$HOME/.bashrc"
    echo "alias nh='$NH_INSTALL_DIR/start-nethunter.sh $architecture'" >> "$HOME/.bashrc"
    
    # Also add to .profile for other shells
    if [ -f "$HOME/.profile" ]; then
        if ! grep -q "alias nethunter=" "$HOME/.profile"; then
            echo "alias nethunter='$NH_INSTALL_DIR/start-nethunter.sh $architecture'" >> "$HOME/.profile"
            echo "alias nh='$NH_INSTALL_DIR/start-nethunter.sh $architecture'" >> "$HOME/.profile"
        fi
    fi
    
    nh_log "SUCCESS" "Aliases created"
    nh_log "INFO" "You may need to restart Termux or run 'source ~/.bashrc' for aliases to work"
    
    return 0
}

# Main installation function
nh_install() {
    local image_type=${1:-"$NH_DEFAULT_IMAGE_TYPE"}
    local architecture=${2:-$(nh_check_architecture)}
    
    nh_log "INFO" "Starting NetHunter installation"
    nh_log "INFO" "Image type: $image_type"
    nh_log "INFO" "Architecture: $architecture"
    
    # Install required packages
    nh_install_packages proot tar wget curl coreutils pv || {
        nh_log "WARNING" "Some packages could not be installed, but continuing anyway"
    }
    
    # Create backup of existing installation if it exists
    if [ -d "$NH_INSTALL_DIR/kali-$architecture" ]; then
        nh_log "INFO" "Existing installation found"
        
        if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Backup existing installation before proceeding? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                nh_create_backup "$NH_INSTALL_DIR/kali-$architecture" "nethunter_backup_$(date +%Y%m%d_%H%M%S)"
            fi
        fi
    fi
    
    # Download and extract rootfs
    if ! nh_download_rootfs "$image_type" "$architecture"; then
        nh_log "ERROR" "Failed to download and extract rootfs"
        return 1
    fi
    
    # Create launch script
    if ! nh_create_launch_script "$architecture"; then
        nh_log "ERROR" "Failed to create launch script"
        return 1
    fi
    
    # Create desktop shortcut
    if ! nh_create_desktop_shortcut "$architecture"; then
        nh_log "WARNING" "Failed to create desktop shortcut"
    fi
    
    # Create aliases
    if ! nh_create_aliases "$architecture"; then
        nh_log "WARNING" "Failed to create aliases"
    fi
    
    # Save configuration
    NH_DEFAULT_IMAGE_TYPE="$image_type"
    nh_save_config
    
    nh_log "SUCCESS" "NetHunter installation completed successfully"
    nh_log "INFO" "To start NetHunter, run: nethunter or nh"
    nh_log "INFO" "You can also use the shortcut in the Termux widget"
    
    return 0
}

# Uninstall NetHunter
nh_uninstall() {
    nh_log "INFO" "Uninstalling NetHunter"
    
    # Ask for confirmation if not in force mode
    if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
        read -p "Are you sure you want to uninstall NetHunter? This will remove all data. (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            nh_log "INFO" "Uninstallation cancelled"
            return 0
        fi
    fi
    
    # Create backup if requested
    if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
        read -p "Create backup before uninstalling? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nh_create_backup "$NH_INSTALL_DIR" "nethunter_backup_$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    # Remove installation directory
    if [ -d "$NH_INSTALL_DIR" ]; then
        nh_log "INFO" "Removing installation directory"
        rm -rf "$NH_INSTALL_DIR"
    fi
    
    # Remove desktop shortcut
    if [ -f "$HOME/.shortcuts/NetHunter" ]; then
        nh_log "INFO" "Removing desktop shortcut"
        rm -f "$HOME/.shortcuts/NetHunter"
    fi
    
    # Remove aliases
    nh_log "INFO" "Removing aliases"
    if grep -q "alias nethunter=" "$HOME/.bashrc"; then
        sed -i '/alias nethunter=/d' "$HOME/.bashrc"
    fi
    if grep -q "alias nh=" "$HOME/.bashrc"; then
        sed -i '/alias nh=/d' "$HOME/.bashrc"
    fi
    
    # Remove from .profile if it exists
    if [ -f "$HOME/.profile" ]; then
        if grep -q "alias nethunter=" "$HOME/.profile"; then
            sed -i '/alias nethunter=/d' "$HOME/.profile"
        fi
        if grep -q "alias nh=" "$HOME/.profile"; then
            sed -i '/alias nh=/d' "$HOME/.profile"
        fi
    fi
    
    # Ask if user wants to remove configuration and cache
    if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
        read -p "Remove configuration and cache files? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nh_log "INFO" "Removing configuration and cache"
            rm -rf "$NH_CONFIG_DIR"
        fi
    elif [ "$NH_FORCE_MODE" = "true" ]; then
        nh_log "INFO" "Removing configuration and cache (force mode)"
        rm -rf "$NH_CONFIG_DIR"
    fi
    
    nh_log "SUCCESS" "NetHunter uninstalled successfully"
    return 0
}

# Update NetHunter
nh_update() {
    local image_type=${1:-"$NH_DEFAULT_IMAGE_TYPE"}
    local architecture=${2:-$(nh_check_architecture)}
    
    nh_log "INFO" "Updating NetHunter"
    nh_log "INFO" "Image type: $image_type"
    nh_log "INFO" "Architecture: $architecture"
    
    # Create backup of existing installation if it exists
    if [ -d "$NH_INSTALL_DIR/kali-$architecture" ]; then
        nh_log "INFO" "Existing installation found"
        
        if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Backup existing installation before updating? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                nh_create_backup "$NH_INSTALL_DIR/kali-$architecture" "nethunter_backup_$(date +%Y%m%d_%H%M%S)"
            fi
        fi
    else
        nh_log "WARNING" "No existing installation found, performing fresh install"
        nh_install "$image_type" "$architecture"
        return $?
    fi
    
    # Download and extract rootfs
    if ! nh_download_rootfs "$image_type" "$architecture"; then
        nh_log "ERROR" "Failed to download and extract rootfs"
        return 1
    fi
    
    # Update launch script
    if ! nh_create_launch_script "$architecture"; then
        nh_log "ERROR" "Failed to update launch script"
        return 1
    fi
    
    # Update desktop shortcut
    if ! nh_create_desktop_shortcut "$architecture"; then
        nh_log "WARNING" "Failed to update desktop shortcut"
    fi
    
    # Update aliases
    if ! nh_create_aliases "$architecture"; then
        nh_log "WARNING" "Failed to update aliases"
    fi
    
    # Save configuration
    NH_DEFAULT_IMAGE_TYPE="$image_type"
    nh_save_config
    
    nh_log "SUCCESS" "NetHunter updated successfully"
    nh_log "INFO" "To start NetHunter, run: nethunter or nh"
    
    return 0
}
