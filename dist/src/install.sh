#!/data/data/com.termux/files/usr/bin/bash
# install.sh - Installation functions for NetHunter Installer
# Version: 3.1 (May 2025) - Updated download logic

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
    source "$SCRIPT_DIR/utils.sh"
fi

# ===== Installation Functions =====

# Get image URL based on type and architecture (Updated Logic)
nh_get_image_url() {
    local image_type=$1
    local architecture=$2
    # Define the base URL for NetHunter images
    local base_url="https://kali.download/nethunter-images/"
    # Define the Kali version to use (Consider making this dynamic later)
    local kali_version="kali-2025.1c"
    
    nh_log "INFO" "Looking for image: type=$image_type, arch=$architecture, version=$kali_version"
    
    # Construct the direct download URL
    local image_url="${base_url}${kali_version}/rootfs/kali-nethunter-rootfs-${image_type}-${architecture}.tar.xz"
    
    nh_log "DEBUG" "Constructed URL: $image_url"
    
    # Verify the URL is accessible
    if nh_check_url "$image_url"; then
        nh_log "INFO" "Found image URL: $image_url"
        echo "$image_url"
        return 0
    else
        nh_log "ERROR" "Image URL is not accessible or does not exist: $image_url"
        nh_log "ERROR" "Please check image type ('$image_type'), architecture ('$architecture'), and Kali version ('$kali_version')."
        nh_log "ERROR" "You can browse available images at: ${base_url}${kali_version}/rootfs/"
        return 1
    fi
}

# Download and extract rootfs
nh_download_rootfs() {
    local image_type=$1
    local architecture=$2
    
    nh_log "INFO" "Preparing to download rootfs (type: $image_type, arch: $architecture)"
    
    # Get image URL using the updated function
    local image_url=$(nh_get_image_url "$image_type" "$architecture")
    if [ -z "$image_url" ]; then
        nh_log "ERROR" "Failed to get a valid image URL for the specified type and architecture."
        return 1
    fi
    
    # Determine required space based on image type (Keep existing logic, maybe refine later)
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
    local rootfs_filename="kali-nethunter-rootfs-${image_type}-${architecture}.tar.xz"
    local rootfs_file="$NH_CACHE_DIR/$rootfs_filename"
    nh_log "INFO" "Attempting to download rootfs from: $image_url"
    if ! nh_download_file "$image_url" "$rootfs_file" "rootfs"; then
        return 1
    fi
    
    # Extract rootfs
    local extract_dir="$NH_INSTALL_DIR/kali-$architecture"
    nh_log "INFO" "Extracting rootfs archive to $extract_dir"
    if ! nh_extract_archive "$rootfs_file" "$extract_dir"; then
        return 1
    fi
    
    # Clean up if not keeping archive
    if [ "$NH_KEEP_ARCHIVE" != "true" ]; then
        nh_log "INFO" "Removing downloaded archive: $rootfs_file"
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
    
    # Use architecture variable correctly in the script path
    cat > "$launch_script" << EOL
#!/data/data/com.termux/files/usr/bin/bash
cd \$(dirname \$0)
## Start NetHunter for $architecture
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r kali-${architecture}"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b /data"
command+=" -b /vendor"
command+=" -b /system"
command+=" -b kali-${architecture}/root:/dev/shm"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$2 \$3 \$4 \$5 \$6 \$7 \$8 \$9"
if [ -z "\$2" ]; then
    exec \$command
else
    \$command -c "\$com"
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
cd $NH_INSTALL_DIR && ./start-nethunter.sh
EOF
    
    chmod 700 "$shortcut_file"
    
    nh_log "SUCCESS" "Desktop shortcut created at $shortcut_file"
    return 0
}

# Create aliases
nh_create_aliases() {
    local architecture=$1 # Keep arch parameter for consistency, though script path is now fixed
    
    nh_log "INFO" "Creating aliases"
    
    # Check if aliases already exist
    if grep -q "alias nethunter=" "$HOME/.bashrc"; then
        nh_log "INFO" "Updating existing aliases"
        sed -i '/alias nethunter=/d' "$HOME/.bashrc"
        sed -i '/alias nh=/d' "$HOME/.bashrc"
    fi
    
    # Add new aliases (Point to the generic start script)
    echo "alias nethunter='$NH_INSTALL_DIR/start-nethunter.sh'" >> "$HOME/.bashrc"
    echo "alias nh='$NH_INSTALL_DIR/start-nethunter.sh'" >> "$HOME/.bashrc"
    
    # Also add to .profile for other shells
    if [ -f "$HOME/.profile" ]; then
        if ! grep -q "alias nethunter=" "$HOME/.profile"; then
            echo "alias nethunter='$NH_INSTALL_DIR/start-nethunter.sh'" >> "$HOME/.profile"
            echo "alias nh='$NH_INSTALL_DIR/start-nethunter.sh'" >> "$HOME/.profile"
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
        nh_log "INFO" "Existing installation found for $architecture"
        
        if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Backup existing installation before proceeding? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                nh_create_backup "$NH_INSTALL_DIR/kali-$architecture" "nethunter_${architecture}_backup_$(date +%Y%m%d_%H%M%S)"
            fi
            # Ask if user wants to remove the old installation before proceeding
            read -p "Remove existing installation directory '$NH_INSTALL_DIR/kali-$architecture' before installing new one? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                 nh_log "INFO" "Removing existing installation directory: $NH_INSTALL_DIR/kali-$architecture"
                 rm -rf "$NH_INSTALL_DIR/kali-$architecture"
            else
                 nh_log "ERROR" "Cannot proceed with installation while existing directory exists. Please remove it manually or allow removal."
                 return 1
            fi
        elif [ "$NH_FORCE_MODE" = "true" ]; then
             nh_log "INFO" "Removing existing installation directory (force mode): $NH_INSTALL_DIR/kali-$architecture"
             rm -rf "$NH_INSTALL_DIR/kali-$architecture"
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
        # Consider cleanup here if needed
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
    
    # Save configuration (Update default type)
    NH_DEFAULT_IMAGE_TYPE="$image_type"
    nh_save_config
    
    nh_log "SUCCESS" "NetHunter installation completed successfully for $architecture"
    nh_log "INFO" "To start NetHunter, run: nethunter or nh"
    nh_log "INFO" "You can also use the shortcut in the Termux widget"
    
    return 0
}

# Uninstall NetHunter
nh_uninstall() {
    nh_log "INFO" "Uninstalling NetHunter"
    
    # Detect installed architecture(s)
    local installed_archs=()
    if [ -d "$NH_INSTALL_DIR" ]; then
        installed_archs=($(find "$NH_INSTALL_DIR" -maxdepth 1 -type d -name 'kali-*' -printf '%f\n' | sed 's/kali-//'))
    fi

    if [ ${#installed_archs[@]} -eq 0 ]; then
        nh_log "WARNING" "No NetHunter installation found to uninstall."
    else 
        nh_log "INFO" "Found installations for architectures: ${installed_archs[*]}"
    fi

    # Ask for confirmation if not in force mode
    if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ]; then
        read -p "Are you sure you want to uninstall NetHunter? This will remove all data for found architectures. (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            nh_log "INFO" "Uninstallation cancelled"
            return 0
        fi
    fi
    
    # Create backup if requested (Backup the whole install dir)
    if [ "$NH_FORCE_MODE" != "true" ] && [ "$NH_AUTO_MODE" != "true" ] && [ -d "$NH_INSTALL_DIR" ]; then
        read -p "Create backup of '$NH_INSTALL_DIR' before uninstalling? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            nh_create_backup "$NH_INSTALL_DIR" "nethunter_full_backup_$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    # Remove installation directory
    if [ -d "$NH_INSTALL_DIR" ]; then
        nh_log "INFO" "Removing installation directory: $NH_INSTALL_DIR"
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
        read -p "Remove configuration and cache files ($NH_CONFIG_DIR)? (y/n) " -n 1 -r
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

# Update NetHunter (Simplified: Essentially reinstall)
# TODO: Implement a more sophisticated update mechanism if possible
nh_update() {
    local image_type=${1:-"$NH_DEFAULT_IMAGE_TYPE"}
    local architecture=${2:-$(nh_check_architecture)}
    
    nh_log "INFO" "Updating NetHunter for $architecture (This will perform a fresh install)"
    nh_log "INFO" "Image type: $image_type"
    
    # Force mode is implicitly enabled for update's reinstall logic
    local original_force_mode=$NH_FORCE_MODE
    NH_FORCE_MODE=true 
    
    nh_install "$image_type" "$architecture"
    local install_status=$?
    
    # Restore original force mode setting
    NH_FORCE_MODE=$original_force_mode 
    
    if [ $install_status -eq 0 ]; then
        nh_log "SUCCESS" "NetHunter update (reinstall) completed successfully for $architecture"
    else
        nh_log "ERROR" "NetHunter update (reinstall) failed for $architecture"
    fi
    
    return $install_status
}

# --- Obsolete Function --- 
# nh_fetch_image_list() { ... } # Removed as index.json is no longer used

