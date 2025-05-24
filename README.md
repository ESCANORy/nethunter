# NetHunter CLI - توثيق شامل للأداة المتقدمة

## 1. نظرة عامة

NetHunter CLI هي أداة متقدمة ومتكاملة لتثبيت وإدارة Kali NetHunter في بيئة Termux على أجهزة Android. تم تطوير هذه الأداة بمعايير هندسية وأمنية عالية، مع التركيز على المرونة والموثوقية والأمان.

### 1.1 الميزات الرئيسية

- **بنية وحدات متكاملة**: تقسيم الكود إلى وحدات منفصلة ومستقلة
- **توقيع رقمي**: التحقق من سلامة السكربت والملفات المنزلة
- **واجهة سطر أوامر متكاملة**: دعم كامل للأعلام والخيارات المتقدمة
- **جلب الصور ديناميكياً**: تحميل قائمة الصور من JSON واختيار تلقائي
- **نظام سجلات متقدم**: تسجيل مفصل لمعلومات النظام والأداء
- **تشغيل آلي**: دعم التثبيت بدون تدخل يدوي
- **نسخ احتياطي واستعادة**: وظائف مدمجة للنسخ الاحتياطي والاستعادة
- **اختبارات متكاملة**: إطار اختبار كامل للوحدات والتكامل

## 2. البنية الهندسية

### 2.1 هيكل الملفات

```
nethunter-cli-advanced/
├── nethunter-cli           # نقطة الدخول الرئيسية
├── src/                    # مجلد الوحدات البرمجية
│   ├── core.sh             # الوظائف والمتغيرات الأساسية
│   ├── utils.sh            # وظائف مساعدة
│   ├── install.sh          # وظائف التثبيت
│   ├── gpg.sh              # وظائف التوقيع الرقمي
│   ├── cli.sh              # واجهة سطر الأوامر
│   └── logging.sh          # نظام السجلات المتقدم
├── README.md               # توثيق شامل
└── test.sh                 # إطار الاختبار
```

### 2.2 تدفق العمل

1. **التهيئة**: تحميل الوحدات وإعداد البيئة
2. **تحليل الأوامر**: معالجة أوامر المستخدم والأعلام
3. **التحقق**: فحص البيئة والمتطلبات
4. **التنفيذ**: تنفيذ العملية المطلوبة (تثبيت، تحديث، إلخ)
5. **التسجيل**: تسجيل النتائج والأحداث
6. **التنظيف**: تنظيف الملفات المؤقتة

## 3. الوحدات البرمجية

### 3.1 وحدة النواة (core.sh)

```bash
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

# Default settings
NH_DEFAULT_IMAGE_TYPE="full"
NH_KEEP_ARCHIVE=false
NH_QUIET_MODE=false
NH_VERBOSE_MODE=false
NH_AUTO_MODE=false
NH_FORCE_MODE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# ... (المزيد من الوظائف الأساسية)
```

### 3.2 وحدة الأدوات المساعدة (utils.sh)

```bash
#!/usr/bin/env bash
# utils.sh - Utility functions for NetHunter Installer
# Version: 3.0 (May 2025)

# Source core functions if not already loaded
if [ -z "$NH_VERSION" ]; then
    # Determine script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
fi

# ===== Utility Functions =====

# Check if URL exists
nh_check_url() {
    local url="$1"
    local timeout=${2:-10}
    
    nh_log "DEBUG" "Checking URL: $url"
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s --head --request GET --max-time "$timeout" "$url" | grep "200 OK\|302 Found" >/dev/null; then
            nh_log "DEBUG" "URL exists: $url"
            return 0
        else
            nh_log "DEBUG" "URL does not exist: $url"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget --spider --timeout="$timeout" "$url" 2>/dev/null; then
            nh_log "DEBUG" "URL exists: $url"
            return 0
        else
            nh_log "DEBUG" "URL does not exist: $url"
            return 1
        fi
    else
        nh_log "ERROR" "Neither curl nor wget is available"
        return 2
    fi
}

# Check device architecture
nh_check_architecture() {
    nh_log "INFO" "Checking device architecture"
    
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
            nh_log "ERROR" "Unsupported architecture: $arch"
            echo "unknown"
            return 1
            ;;
    esac
    
    return 0
}

# ... (المزيد من وظائف الأدوات المساعدة)
```

### 3.3 وحدة التثبيت (install.sh)

```bash
#!/usr/bin/env bash
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

# Fetch image list from JSON
nh_fetch_image_list() {
    nh_log "INFO" "Fetching image list"
    
    local image_list_url="https://kali.download/nethunter-images/current/rootfs/index.json"
    local image_list_file="$NH_CACHE_DIR/image_index.json"
    
    # Check if we already have a cached copy
    if [ -f "$image_list_file" ]; then
        # Check if it's less than 24 hours old
        local file_age=$(( $(date +%s) - $(stat -c %Y "$image_list_file") ))
        if [ $file_age -lt 86400 ]; then
            nh_log "DEBUG" "Using cached image list (age: ${file_age}s)"
            return 0
        fi
    fi
    
    # Download the image list
    nh_log "INFO" "Downloading image list from $image_list_url"
    
    if command -v curl >/dev/null 2>&1; then
        if ! curl -s -o "$image_list_file" "$image_list_url"; then
            nh_log "WARNING" "Failed to download image list, using default URLs"
            nh_create_default_image_list
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q -O "$image_list_file" "$image_list_url"; then
            nh_log "WARNING" "Failed to download image list, using default URLs"
            nh_create_default_image_list
            return 1
        fi
    else
        nh_log "ERROR" "Neither curl nor wget is available"
        nh_create_default_image_list
        return 2
    fi
    
    nh_log "SUCCESS" "Image list downloaded successfully"
    return 0
}

# ... (المزيد من وظائف التثبيت)
```

### 3.4 وحدة التوقيع الرقمي (gpg.sh)

```bash
#!/usr/bin/env bash
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

# Initialize GPG
nh_gpg_init() {
    nh_log "INFO" "Initializing GPG"
    
    # Create GPG directory
    local gpg_dir="$NH_CONFIG_DIR/gpg"
    mkdir -p "$gpg_dir"
    chmod 700 "$gpg_dir"
    
    # Set GPG home directory
    export GNUPGHOME="$gpg_dir"
    
    # Check if GPG is installed
    if ! command -v gpg >/dev/null 2>&1; then
        nh_log "WARNING" "GPG not found, installing..."
        nh_install_packages gnupg
    fi
    
    nh_log "SUCCESS" "GPG initialized"
    return 0
}

# ... (المزيد من وظائف التوقيع الرقمي)
```

### 3.5 وحدة واجهة سطر الأوامر (cli.sh)

```bash
#!/usr/bin/env bash
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

# ... (المزيد من وظائف واجهة سطر الأوامر)
```

### 3.6 وحدة السجلات المتقدمة (logging.sh)

```bash
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

# ... (المزيد من وظائف السجلات المتقدمة)
```

### 3.7 نقطة الدخول الرئيسية (nethunter-cli)

```bash
#!/usr/bin/env bash
# nethunter-cli - Main entry point for NetHunter CLI
# Version: 3.0 (May 2025)

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
source "$SCRIPT_DIR/src/core.sh"
source "$SCRIPT_DIR/src/utils.sh"
source "$SCRIPT_DIR/src/install.sh"
source "$SCRIPT_DIR/src/gpg.sh"
source "$SCRIPT_DIR/src/cli.sh"
source "$SCRIPT_DIR/src/logging.sh"

# Run CLI main function
nh_cli_main "$@"

# Exit with the return code from the main function
exit $?
```

## 4. الميزات المتقدمة

### 4.1 التوقيع الرقمي والتحقق من السلامة

تستخدم الأداة GPG للتوقيع الرقمي والتحقق من سلامة السكربت والملفات المنزلة:

```bash
# التحقق من سلامة السكربت
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

# التحقق من سلامة الملف المنزل
nh_verify_download() {
    local file="$1"
    local expected_hash="$2"
    
    nh_log "INFO" "Verifying download integrity: $file"
    
    if [ -z "$expected_hash" ]; then
        nh_log "WARNING" "No hash provided for verification, skipping"
        return 0
    fi
    
    local actual_hash=$(sha256sum "$file" | awk '{print $1}')
    
    if [ "$actual_hash" = "$expected_hash" ]; then
        nh_log "SUCCESS" "File integrity verified: $file"
        return 0
    else
        nh_log "ERROR" "File integrity check failed: $file"
        nh_log "ERROR" "Expected: $expected_hash"
        nh_log "ERROR" "Actual: $actual_hash"
        return 1
    fi
}
```

### 4.2 جلب الصور ديناميكياً

تستخدم الأداة JSON لجلب قائمة الصور المتاحة ديناميكياً:

```bash
# الحصول على رابط الصورة من JSON
nh_get_image_url() {
    local image_type="$1"
    local architecture="$2"
    local image_list_file="$NH_CACHE_DIR/image_index.json"
    
    nh_log "INFO" "Getting image URL for type: $image_type, arch: $architecture"
    
    # Ensure we have the image list
    if [ ! -f "$image_list_file" ]; then
        nh_fetch_image_list
    fi
    
    # Parse JSON to get URL
    if command -v jq >/dev/null 2>&1; then
        # Use jq to parse JSON
        local url=$(jq -r ".images[] | select(.type == \"$image_type\" and .arch == \"$architecture\") | .url" "$image_list_file")
        
        if [ -z "$url" ] || [ "$url" = "null" ]; then
            nh_log "WARNING" "Image not found in JSON, using default URL"
            url="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-$image_type-$architecture.tar.xz"
        fi
    else
        # Fallback to grep/sed if jq is not available
        nh_log "WARNING" "jq not found, using basic JSON parsing"
        url="https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-$image_type-$architecture.tar.xz"
    fi
    
    nh_log "INFO" "Image URL: $url"
    echo "$url"
    return 0
}
```

### 4.3 نظام السجلات المتقدم

تتضمن الأداة نظام سجلات متقدم يسجل معلومات النظام والأداء:

```bash
# تسجيل معلومات النظام المفصلة
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
```

### 4.4 إطار الاختبار

تتضمن الأداة إطار اختبار شامل للوحدات والتكامل:

```bash
#!/usr/bin/env bash
# test.sh - Test framework for NetHunter CLI
# Version: 3.0 (May 2025)

# Set up test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$TEST_DIR/src"
TEST_TEMP_DIR="$TEST_DIR/test_tmp"
TEST_LOG_DIR="$TEST_TEMP_DIR/logs"
TEST_RESULTS_DIR="$TEST_TEMP_DIR/results"

# Test configuration
TEST_VERBOSE=true
TEST_CLEANUP=true
TEST_TIMEOUT=30  # seconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize test environment
init_test_env() {
    echo -e "${BLUE}[*] Initializing test environment${NC}"
    
    # Create test directories
    mkdir -p "$TEST_TEMP_DIR" "$TEST_LOG_DIR" "$TEST_RESULTS_DIR"
    
    # Set up environment variables for testing
    export NH_CONFIG_DIR="$TEST_TEMP_DIR/config"
    export NH_LOG_DIR="$TEST_LOG_DIR"
    export NH_INSTALL_DIR="$TEST_TEMP_DIR/nethunter"
    export NH_CACHE_DIR="$TEST_TEMP_DIR/cache"
    export NH_TEMP_DIR="$TEST_TEMP_DIR/temp"
    export NH_DEV_MODE=true
    
    # Create test image index
    mkdir -p "$NH_CACHE_DIR"
    cat > "$NH_CACHE_DIR/image_index.json" << EOF
{
  "images": [
    {"type": "full", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-full-arm64.tar.xz", "size": "2.1GB"},
    {"type": "minimal", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-minimal-arm64.tar.xz", "size": "130MB"},
    {"type": "nano", "arch": "arm64", "url": "https://kali.download/nethunter-images/current/rootfs/kali-nethunter-rootfs-nano-arm64.tar.xz", "size": "180MB"}
  ]
}
EOF
    
    echo -e "${GREEN}[✓] Test environment initialized${NC}"
}

# ... (المزيد من وظائف الاختبار)
```

## 5. طريقة الاستخدام

### 5.1 التثبيت السريع

```bash
# تثبيت سريع بأمر واحد
curl -sL https://bit.ly/kali-nh-termux | bash
```

### 5.2 التثبيت اليدوي

```bash
# تنزيل الأداة
curl -sL https://github.com/ESCANORy/nethunter-cli-advanced/archive/refs/heads/main.zip -o nethunter-cli.zip
unzip nethunter-cli.zip
cd nethunter-cli-advanced-main

# جعل السكربت قابل للتنفيذ
chmod +x nethunter-cli

# تشغيل الأداة
./nethunter-cli install
```

### 5.3 الأوامر الأساسية

```bash
# تثبيت NetHunter بالإعدادات الافتراضية
nethunter-cli install

# تثبيت نوع محدد من الصور
nethunter-cli install --type minimal

# تحديث التثبيت الحالي
nethunter-cli update

# إلغاء تثبيت NetHunter
nethunter-cli uninstall

# إنشاء نسخة احتياطية
nethunter-cli backup

# استعادة من نسخة احتياطية
nethunter-cli restore

# التحقق من التثبيت
nethunter-cli verify

# عرض المساعدة
nethunter-cli help
```

### 5.4 الخيارات المتقدمة

```bash
# تثبيت بمعمارية محددة
nethunter-cli install --type minimal --arch arm64

# تثبيت في وضع غير تفاعلي
nethunter-cli install --yes

# تثبيت في مجلد مخصص
nethunter-cli install --dir ~/custom-nethunter

# الاحتفاظ بالأرشيف بعد التثبيت
nethunter-cli install --keep-archive

# تنفيذ العملية بدون تأكيد
nethunter-cli update --force

# تشغيل في وضع صامت
nethunter-cli install --quiet

# تشغيل في وضع مفصل
nethunter-cli install --verbose

# تعطيل الألوان
nethunter-cli install --no-color
```

## 6. أنواع الصور

| النوع | الوصف | الحجم | موصى به لـ |
|------|-------------|------|-----------------|
| full | Kali NetHunter كامل مع جميع الأدوات | ~2.1GB | اختبار الاختراق الكامل |
| minimal | Kali NetHunter أساسي مع الأدوات الضرورية | ~130MB | الأجهزة ذات التخزين المحدود |
| nano | تثبيت الحد الأدنى مع الوظائف الأساسية | ~180MB | التخزين المحدود جداً أو الاختبار |

## 7. دعم المعماريات

- **arm64**: أجهزة ARM 64-bit الحديثة (معظم هواتف/أجهزة Android)
- **armhf**: أجهزة ARM 32-bit (أجهزة Android القديمة)
- **amd64**: أجهزة x86 64-bit (Android-x86 على PC/laptop)
- **i386**: أجهزة x86 32-bit (تثبيتات Android-x86 القديمة)

## 8. التكوين

تستخدم الأداة ملف تكوين JSON موجود في `~/.nethunter/config.json`. يتم إنشاء هذا الملف تلقائياً عند التشغيل الأول ولكن يمكن تعديله يدوياً للتخصيص المتقدم.

مثال على التكوين:

```json
{
  "install_dir": "/data/data/com.termux/files/home/nethunter",
  "default_image_type": "full",
  "keep_archive": false,
  "check_integrity": true,
  "script_hash": "SELF_HASH_PLACEHOLDER",
  "updated_at": "2025-05-20 00:25:00"
}
```

## 9. السجلات

تحتفظ الأداة بسجلات مفصلة لجميع العمليات في `~/.nethunter/logs/`. تتضمن هذه السجلات:

- معلومات النظام
- تفاصيل تنفيذ الأوامر
- مقاييس الأداء
- تقارير الأخطاء
- ملخصات التثبيت

يتم تدوير السجلات تلقائياً لمنع استخدام القرص المفرط.

### 9.1 تقارير الأعطال

في حالة حدوث أخطاء، يتم إنشاء تقارير أعطال في `~/.nethunter/logs/crashes/`. تحتوي هذه التقارير على معلومات مفصلة عن الخطأ وحالة النظام، مما يمكن أن يكون مفيداً لاستكشاف الأخطاء وإصلاحها.

## 10. ميزات الأمان

### 10.1 التحقق من التوقيع الرقمي

يمكن للأداة التحقق من صحة السكربتات والتنزيلات باستخدام توقيعات GPG. يتم تضمين المفتاح العام في التوزيع واستيراده تلقائياً أثناء التثبيت.

### 10.2 التحقق من السلامة

يتم التحقق من سلامة الملف باستخدام تجزئات SHA-256 للتأكد من أن التنزيلات غير تالفة أو تم العبث بها.

### 10.3 مبدأ أقل امتياز

تم تصميم الأداة للعمل بأقل امتيازات ممكنة وسترفض العمل كـ root لأسباب أمنية.

## 11. استكشاف الأخطاء وإصلاحها

### 11.1 المشاكل الشائعة

#### فشل التثبيت مع "مساحة غير كافية"

تأكد من توفر مساحة تخزين كافية. تتطلب الصورة الكاملة حوالي 3 جيجابايت من المساحة الحرة.

```bash
# التحقق من المساحة المتوفرة
df -h

# محاولة تثبيت صورة أصغر
nethunter-cli install --type minimal
```

#### "الأمر غير موجود" بعد التثبيت

قد لا يتم تحميل الاختصارات. جرب:

```bash
source ~/.bashrc
# أو
source ~/.profile
```

#### لا يمكن الاتصال بالإنترنت من NetHunter

تحقق من تكوين الشبكة وتأكد من أن Termux لديه أذونات الإنترنت.

```bash
# اختبار الاتصال في Termux
ping -c 1 8.8.8.8

# اختبار تحليل DNS
nslookup kali.org
```

#### فشل التحقق من GPG

قد يشير هذا إلى العبث أو تنزيل تالف. حاول إعادة التثبيت من المصدر الرسمي.

```bash
# فرض إعادة التثبيت مع التحقق من السلامة
nethunter-cli install --force
```

### 11.2 تحليل السجلات

يمكن أن تكون السجلات مفيدة لتشخيص المشكلات:

```bash
# عرض أحدث سجل
cat $(ls -t ~/.nethunter/logs/*.log | head -1)

# البحث عن الأخطاء في السجلات
grep ERROR ~/.nethunter/logs/*.log
```

## 12. التطوير

### 12.1 البنية الوحدات

تم تنظيم الأداة في الوحدات التالية:

- **core.sh**: الوظائف والمتغيرات الأساسية
- **utils.sh**: وظائف مساعدة
- **install.sh**: وظائف التثبيت
- **gpg.sh**: وظائف التحقق من التوقيع الرقمي
- **cli.sh**: وظائف واجهة سطر الأوامر
- **logging.sh**: وظائف السجلات المحسنة

### 12.2 إضافة ميزات جديدة

لإضافة ميزات جديدة، قم بإنشاء وحدة جديدة أو توسيع وحدة موجودة. تأكد من أن الكود يتبع الأنماط الموجودة ويتضمن تسجيل وإدارة أخطاء مناسبة.

### 12.3 الاختبار

تتضمن الأداة إطار اختبار للتحقق من الوظائف:

```bash
# تشغيل جميع الاختبارات
./test.sh

# تشغيل اختبار محدد
./test.sh install
```

### 12.4 البناء من المصدر

لبناء الأداة من المصدر:

```bash
# استنساخ المستودع
git clone https://github.com/ESCANORy/nethunter-cli-advanced.git
cd nethunter-cli-advanced

# تثبيت تبعيات التطوير
pkg install jq gpg

# بناء الحزمة
./build.sh
```

## 13. التكامل

### 13.1 تكامل CI/CD

يمكن دمج الأداة في خطوط أنابيب CI/CD باستخدام الوضع غير التفاعلي:

```bash
nethunter-cli install --yes --type minimal --quiet
```

### 13.2 تكامل Webhook

للمراقبة عن بعد، قم بتكوين عنوان URL لـ webhook في ملف التكوين:

```json
{
  "webhook_url": "https://example.com/webhook"
}
```

سيتم إرسال السجلات وتقارير الأعطال تلقائياً إلى عنوان URL هذا.

## 14. المساهمة

المساهمات مرحب بها! يرجى اتباع هذه الخطوات:

1. انسخ المستودع
2. أنشئ فرع ميزة
3. قم بإجراء تغييراتك
4. أضف اختبارات للوظائف الجديدة
5. قدم طلب سحب

يرجى التأكد من أن الكود يتبع معايير الترميز للمشروع ويتضمن وثائق مناسبة.

## 15. الترخيص

هذا المشروع مرخص بموجب ترخيص GPL-3.0 - راجع ملف LICENSE للحصول على التفاصيل.

## 16. شكر وتقدير

- فريق Kali Linux لـ NetHunter
- مطوري Termux
- جميع المساهمين في المشروع

---

*هذه الأداة ليست تابعة رسمياً لـ Kali Linux أو Termux ما لم يُذكر خلاف ذلك.*
