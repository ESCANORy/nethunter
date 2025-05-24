#!/data/data/com.termux/files/usr/bin/bash
# gpg.sh - GPG signature verification functions for NetHunter Installer
# Version: 3.0 (May 2025)

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
    source "$SCRIPT_DIR/utils.sh"
fi

# ===== GPG Functions =====

# Initialize GPG environment
nh_gpg_init() {
    nh_log "INFO" "Initializing GPG environment"
    
    # Create GPG directory if it doesn't exist
    mkdir -p "$NH_CONFIG_DIR/gpg"
    
    # Set GNUPGHOME to our custom directory
    export GNUPGHOME="$NH_CONFIG_DIR/gpg"
    
    # Check if gpg is installed
    if ! nh_command_exists gpg; then
        nh_log "WARNING" "GPG is not installed, attempting to install"
        nh_install_packages gnupg || {
            nh_log "ERROR" "Failed to install GPG, signature verification will be disabled"
            return 1
        }
    fi
    
    # Initialize GPG with proper permissions
    chmod 700 "$GNUPGHOME"
    
    nh_log "SUCCESS" "GPG environment initialized"
    return 0
}

# Import public key
nh_gpg_import_key() {
    local key_file=$1
    local key_url=${2:-""}
    
    nh_log "INFO" "Importing GPG public key"
    
    # If key_file doesn't exist and key_url is provided, download it
    if [ ! -f "$key_file" ] && [ ! -z "$key_url" ]; then
        nh_log "INFO" "Downloading public key from $key_url"
        nh_download_file "$key_url" "$key_file" "public key" || {
            nh_log "ERROR" "Failed to download public key"
            return 1
        }
    fi
    
    # Check if key file exists and is readable
    if [ ! -f "$key_file" ]; then
        nh_log "ERROR" "Public key file not found: $key_file"
        return 1
    elif [ ! -r "$key_file" ]; then
        nh_log "ERROR" "Public key file is not readable: $key_file"
        nh_log "ERROR" "Please check file permissions."
        return 1
    fi
    
    # Import the key and capture stderr
    local gpg_output
    gpg_output=$(gpg --import "$key_file" 2>&1)
    local gpg_exit_code=$?
    
    if [ $gpg_exit_code -ne 0 ]; then
        nh_log "ERROR" "Failed to import public key (gpg exit code: $gpg_exit_code)"
        nh_log "ERROR" "GPG Output: $gpg_output"
        # Suggest checking permissions, key validity, or GPG setup
        nh_log "ERROR" "Please check GPG setup, key file permissions, and key validity."
        return 1
    fi
    
    # Log success and any potentially useful info from gpg output
    nh_log "DEBUG" "GPG Import Output: $gpg_output"
    nh_log "SUCCESS" "Public key imported successfully"
    return 0
}

# Create default public key
nh_gpg_create_default_key() {
    local key_file="$NH_CONFIG_DIR/gpg/nethunter_public.key"
    
    nh_log "INFO" "Creating default public key"
    
    # Create the key file with the default public key
    cat > "$key_file" << EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=RLXJ
-----END PGP PUBLIC KEY BLOCK-----
EOF
    
    # Import the key
    nh_gpg_import_key "$key_file" || {
        nh_log "ERROR" "Failed to import default public key"
        return 1
    }
    
    nh_log "SUCCESS" "Default public key created and imported"
    return 0
}

# Verify signature
nh_gpg_verify_signature() {
    local file=$1
    local signature_file=${2:-"$file.sig"}
    
    nh_log "INFO" "Verifying signature for $file"
    
    # Check if signature file exists
    if [ ! -f "$signature_file" ]; then
        nh_log "WARNING" "Signature file not found: $signature_file"
        
        # If in development mode, skip verification
        if [ "$NH_DEV_MODE" = "true" ]; then
            nh_log "INFO" "Development mode: skipping signature verification"
            return 0
        fi
        
        # If in force mode, continue anyway
        if [ "$NH_FORCE_MODE" = "true" ]; then
            nh_log "WARNING" "Force mode: continuing without signature verification"
            return 0
        }
        
        # Ask user if they want to continue
        if [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Continue without signature verification? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                nh_log "ERROR" "Signature verification failed"
                return 1
            fi
        else
            nh_log "WARNING" "Auto mode: continuing without signature verification"
        fi
        
        return 0
    fi
    
    # Verify the signature
    gpg --verify "$signature_file" "$file" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        nh_log "ERROR" "Signature verification failed"
        
        # If in development mode, skip verification
        if [ "$NH_DEV_MODE" = "true" ]; then
            nh_log "INFO" "Development mode: ignoring signature verification failure"
            return 0
        fi
        
        # If in force mode, continue anyway
        if [ "$NH_FORCE_MODE" = "true" ]; then
            nh_log "WARNING" "Force mode: continuing despite signature verification failure"
            return 0
        }
        
        # Ask user if they want to continue
        if [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Continue despite signature verification failure? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            nh_log "WARNING" "Auto mode: continuing despite signature verification failure"
        fi
        
        return 0
    fi
    
    nh_log "SUCCESS" "Signature verified successfully"
    return 0
}

# Create signature for a file
nh_gpg_create_signature() {
    local file=$1
    local output_file=${2:-"$file.sig"}
    local key_id=${3:-""}
    
    nh_log "INFO" "Creating signature for $file"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        nh_log "ERROR" "File not found: $file"
        return 1
    fi
    
    # Check if we have a private key
    if [ -z "$key_id" ]; then
        # List available private keys
        local keys=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null)
        
        if [ -z "$keys" ]; then
            nh_log "ERROR" "No private keys found"
            return 1
        fi
        
        # Extract first key ID
        key_id=$(echo "$keys" | grep -o -E "sec\s+[^/]+/([A-F0-9]+)" | head -n 1 | grep -o -E "([A-F0-9]+)$")
        
        if [ -z "$key_id" ]; then
            nh_log "ERROR" "Failed to extract key ID"
            return 1
        fi
    fi
    
    # Create signature
    gpg --detach-sign --armor --default-key "$key_id" -o "$output_file" "$file" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        nh_log "ERROR" "Failed to create signature"
        return 1
    fi
    
    nh_log "SUCCESS" "Signature created at $output_file"
    return 0
}

# Calculate and verify file hash
nh_verify_file_hash() {
    local file=$1
    local expected_hash=$2
    local hash_type=${3:-"sha256"}
    
    nh_log "INFO" "Verifying $hash_type hash for $file"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        nh_log "ERROR" "File not found: $file"
        return 1
    fi
    
    # Calculate hash
    local actual_hash=""
    case "$hash_type" in
        "m            actual_hash=$(md5sum "$file" 2>/dev/null | cut -d ' ' -f 1)
            ;;
        "sha1")
            actual_hash=$(sha1sum "$file" 2>/dev/null | cut -d ' ' -f 1)
            ;;
        "sha256")
            actual_hash=$(sha256sum "$file" 2>/dev/null | cut -d ' ' -f 1)
            ;;
        "sha512")
            actual_hash=$(sha512sum "$file" 2>/dev/null | cut -d ' ' -f 1)          ;;
        *)
            nh_log "ERROR" "Unsupported hash type: $hash_type"
            return 1
            ;;
    esac
    
    # Check if hash calculation failed
    if [ -z "$actual_hash" ]; then
        nh_log "ERROR" "Failed to calculate hash"
        return 1
    fi
    
    # Compare hashes
    if [ "$actual_hash" != "$expected_hash" ]; then
        nh_log "ERROR" "Hash verification failed"
        nh_log "ERROR" "Expected: $expected_hash"
        nh_log "ERROR" "Actual: $actual_hash"
        
        # If in development mode, skip verification
        if [ "$NH_DEV_MODE" = "true" ]; then
            nh_log "INFO" "Development mode: ignoring hash verification failure"
            return 0
        fi
        
        # If in force mode, continue anyway
        if [ "$NH_FORCE_MODE" = "true" ]; then
            nh_log "WARNING" "Force mode: continuing despite hash verification failure"
            return 0
        fi # Corrected brace placement
        
        # Ask user if they want to continue
        if [ "$NH_AUTO_MODE" != "true" ]; then
            read -p "Continue despite hash verification failure? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            nh_log "WARNING" "Auto mode: continuing despite hash verification failure"
        fi
        
        return 0
    fi
    
    nh_log "SUCCESS" "Hash verified successfully"
    return 0
}

# Calculate file hash
nh_calculate_file_hash() {
    local file=$1
    local hash_type=${2:-"sha256"}
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    # Calculate hash
    local hash=""
    case "$hash_type" in
        "md5")
            hash=$(md5sum "$file" 2>/dev/null | awk '{print $1}')
            ;;
        "sha1")
            hash=$(sha1sum "$file" 2>/dev/null | awk '{print $1}')
            ;;
        "sha256")
            hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
            ;;
        "sha512")
            hash=$(sha512sum "$file" 2>/dev/null | awk '{print $1}')
            ;;
        *)
            echo "ERROR: Unsupported hash type: $hash_type"
            return 1
            ;;
    esac
    
    # Check if hash calculation failed
    if [ -z "$hash" ]; then
        echo "ERROR: Failed to calculate hash"
        return 1
    fi
    
    echo "$hash"
    return 0
}
