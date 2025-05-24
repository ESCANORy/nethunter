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

# Clean up test environment
cleanup_test_env() {
    if [ "$TEST_CLEANUP" = true ]; then
        echo -e "${BLUE}[*] Cleaning up test environment${NC}"
        rm -rf "$TEST_TEMP_DIR"
        echo -e "${GREEN}[✓] Test environment cleaned up${NC}"
    else
        echo -e "${YELLOW}[*] Skipping cleanup, test files remain in $TEST_TEMP_DIR${NC}"
    fi
}

# Run a test with timeout
run_test_with_timeout() {
    local test_name=$1
    local test_cmd=$2
    local timeout=$3
    
    echo -e "${BLUE}[*] Running test: $test_name${NC}"
    
    # Create a log file for this test
    local test_log="$TEST_LOG_DIR/test_${test_name}.log"
    
    # Run the test with timeout
    timeout $timeout bash -c "$test_cmd" > "$test_log" 2>&1
    local status=$?
    
    # Check the result
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}[✓] Test passed: $test_name${NC}"
        echo "PASS" > "$TEST_RESULTS_DIR/test_${test_name}.result"
    elif [ $status -eq 124 ]; then
        echo -e "${RED}[!] Test timed out: $test_name${NC}"
        echo "TIMEOUT" > "$TEST_RESULTS_DIR/test_${test_name}.result"
    else
        echo -e "${RED}[!] Test failed: $test_name (exit code: $status)${NC}"
        echo "FAIL" > "$TEST_RESULTS_DIR/test_${test_name}.result"
    fi
    
    # Show test log if verbose or failed
    if [ "$TEST_VERBOSE" = true ] || [ $status -ne 0 ]; then
        echo -e "${YELLOW}--- Test Log ---${NC}"
        cat "$test_log"
        echo -e "${YELLOW}---------------${NC}"
    fi
    
    return $status
}

# Test core module
test_core() {
    echo -e "${BLUE}[*] Testing core module${NC}"
    
    # Test core initialization
    run_test_with_timeout "core_init" "source $SRC_DIR/core.sh && nh_init" $TEST_TIMEOUT
    
    # Test configuration
    run_test_with_timeout "core_config" "source $SRC_DIR/core.sh && nh_create_default_config && nh_load_config" $TEST_TIMEOUT
    
    # Test logging
    run_test_with_timeout "core_logging" "source $SRC_DIR/core.sh && nh_log 'INFO' 'Test message'" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Core module tests completed${NC}"
}

# Test utils module
test_utils() {
    echo -e "${BLUE}[*] Testing utils module${NC}"
    
    # Test URL checking
    run_test_with_timeout "utils_check_url" "source $SRC_DIR/utils.sh && nh_check_url 'https://kali.org'" $TEST_TIMEOUT
    
    # Test architecture detection
    run_test_with_timeout "utils_check_arch" "source $SRC_DIR/utils.sh && nh_check_architecture" $TEST_TIMEOUT
    
    # Test package installation (mock)
    run_test_with_timeout "utils_install_packages" "source $SRC_DIR/utils.sh && function pkg() { echo 'Mock pkg'; return 0; } && nh_install_packages curl wget" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Utils module tests completed${NC}"
}

# Test install module
test_install() {
    echo -e "${BLUE}[*] Testing install module${NC}"
    
    # Test image list fetching
    run_test_with_timeout "install_fetch_image_list" "source $SRC_DIR/install.sh && nh_fetch_image_list" $TEST_TIMEOUT
    
    # Test image URL retrieval
    run_test_with_timeout "install_get_image_url" "source $SRC_DIR/install.sh && nh_get_image_url 'full' 'arm64'" $TEST_TIMEOUT
    
    # Test launch script creation
    run_test_with_timeout "install_create_launch_script" "source $SRC_DIR/install.sh && nh_create_launch_script 'arm64'" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Install module tests completed${NC}"
}

# Test GPG module
test_gpg() {
    echo -e "${BLUE}[*] Testing GPG module${NC}"
    
    # Test GPG initialization
    run_test_with_timeout "gpg_init" "source $SRC_DIR/gpg.sh && nh_gpg_init" $TEST_TIMEOUT
    
    # Test default key creation
    run_test_with_timeout "gpg_create_default_key" "source $SRC_DIR/gpg.sh && nh_gpg_create_default_key" $TEST_TIMEOUT
    
    # Test hash calculation
    run_test_with_timeout "gpg_calculate_hash" "source $SRC_DIR/gpg.sh && echo 'test' > $TEST_TEMP_DIR/test_file && nh_calculate_file_hash '$TEST_TEMP_DIR/test_file'" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] GPG module tests completed${NC}"
}

# Test CLI module
test_cli() {
    echo -e "${BLUE}[*] Testing CLI module${NC}"
    
    # Test argument parsing
    run_test_with_timeout "cli_parse_args" "source $SRC_DIR/cli.sh && nh_parse_args 'install' '--type' 'minimal'" $TEST_TIMEOUT
    
    # Test help display
    run_test_with_timeout "cli_show_help" "source $SRC_DIR/cli.sh && nh_show_help" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] CLI module tests completed${NC}"
}

# Test logging module
test_logging() {
    echo -e "${BLUE}[*] Testing logging module${NC}"
    
    # Test logging initialization
    run_test_with_timeout "logging_init" "source $SRC_DIR/logging.sh && nh_logging_init" $TEST_TIMEOUT
    
    # Test system info logging
    run_test_with_timeout "logging_system_info" "source $SRC_DIR/logging.sh && nh_logging_system_info" $TEST_TIMEOUT
    
    # Test performance logging
    run_test_with_timeout "logging_performance" "source $SRC_DIR/logging.sh && nh_logging_performance 'test' '$(date +%s)'" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Logging module tests completed${NC}"
}

# Test main CLI entry point
test_main_cli() {
    echo -e "${BLUE}[*] Testing main CLI entry point${NC}"
    
    # Test help command
    run_test_with_timeout "main_cli_help" "$TEST_DIR/nethunter-cli help" $TEST_TIMEOUT
    
    # Test version info
    run_test_with_timeout "main_cli_version" "NH_VERSION=\$(grep 'NH_VERSION=' $SRC_DIR/core.sh | cut -d'\"' -f2) && [ ! -z \"\$NH_VERSION\" ]" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Main CLI tests completed${NC}"
}

# Test dry run installation
test_dry_run_install() {
    echo -e "${BLUE}[*] Testing dry run installation${NC}"
    
    # Mock functions to prevent actual downloads and extractions
    cat > "$TEST_TEMP_DIR/mock_functions.sh" << 'EOF'
# Mock download function
nh_download_file() {
    echo "Mock download: $1 -> $2"
    touch "$2"
    return 0
}

# Mock extract function
nh_extract_archive() {
    echo "Mock extract: $1 -> $2"
    mkdir -p "$2"
    touch "$2/mock_extracted_file"
    return 0
}

# Mock check URL function
nh_check_url() {
    echo "Mock check URL: $1"
    return 0
}
EOF
    
    # Run dry installation with mocked functions
    run_test_with_timeout "dry_run_install" "source $SRC_DIR/install.sh && source $TEST_TEMP_DIR/mock_functions.sh && nh_install 'minimal' 'arm64'" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Dry run installation tests completed${NC}"
}

# Test integration between modules
test_integration() {
    echo -e "${BLUE}[*] Testing module integration${NC}"
    
    # Test core + utils integration
    run_test_with_timeout "integration_core_utils" "source $SRC_DIR/core.sh && source $SRC_DIR/utils.sh && nh_init && nh_check_architecture" $TEST_TIMEOUT
    
    # Test install + utils integration
    run_test_with_timeout "integration_install_utils" "source $SRC_DIR/install.sh && source $SRC_DIR/utils.sh && nh_fetch_image_list && nh_check_architecture" $TEST_TIMEOUT
    
    # Test CLI + core integration
    run_test_with_timeout "integration_cli_core" "source $SRC_DIR/cli.sh && source $SRC_DIR/core.sh && nh_parse_args 'help' && nh_show_banner" $TEST_TIMEOUT
    
    echo -e "${GREEN}[✓] Integration tests completed${NC}"
}

# Run all tests
run_all_tests() {
    echo -e "${BLUE}[*] Running all tests${NC}"
    
    # Run individual module tests
    test_core
    test_utils
    test_install
    test_gpg
    test_cli
    test_logging
    
    # Run integration tests
    test_integration
    
    # Run main CLI test
    test_main_cli
    
    # Run dry run installation test
    test_dry_run_install
    
    echo -e "${BLUE}[*] All tests completed${NC}"
}

# Generate test report
generate_test_report() {
    echo -e "${BLUE}[*] Generating test report${NC}"
    
    local total_tests=$(ls -1 "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l)
    local passed_tests=$(grep -l "PASS" "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l)
    local failed_tests=$(grep -l "FAIL" "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l)
    local timeout_tests=$(grep -l "TIMEOUT" "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l)
    
    local pass_percentage=0
    if [ $total_tests -gt 0 ]; then
        pass_percentage=$(( passed_tests * 100 / total_tests ))
    fi
    
    # Generate report file
    local report_file="$TEST_DIR/test_report.md"
    
    cat > "$report_file" << EOF
# NetHunter CLI Test Report

Generated: $(date)

## Summary

- **Total Tests:** $total_tests
- **Passed:** $passed_tests
- **Failed:** $failed_tests
- **Timeouts:** $timeout_tests
- **Pass Rate:** $pass_percentage%

## Test Results

| Test | Result | Log |
|------|--------|-----|
EOF
    
    # Add individual test results
    for result_file in "$TEST_RESULTS_DIR"/*.result; do
        if [ -f "$result_file" ]; then
            local test_name=$(basename "$result_file" .result | sed 's/test_//')
            local result=$(cat "$result_file")
            local log_file="$TEST_LOG_DIR/test_${test_name}.log"
            local log_link="[Log](logs/test_${test_name}.log)"
            
            # Format result with color
            local result_formatted="$result"
            if [ "$result" = "PASS" ]; then
                result_formatted="✅ PASS"
            elif [ "$result" = "FAIL" ]; then
                result_formatted="❌ FAIL"
            elif [ "$result" = "TIMEOUT" ]; then
                result_formatted="⏱️ TIMEOUT"
            fi
            
            echo "| $test_name | $result_formatted | $log_link |" >> "$report_file"
        fi
    done
    
    # Add failed test details
    if [ $failed_tests -gt 0 ] || [ $timeout_tests -gt 0 ]; then
        echo -e "\n## Failed Tests Details\n" >> "$report_file"
        
        for result_file in $(grep -l -E "FAIL|TIMEOUT" "$TEST_RESULTS_DIR"/*.result 2>/dev/null); do
            local test_name=$(basename "$result_file" .result | sed 's/test_//')
            local result=$(cat "$result_file")
            local log_file="$TEST_LOG_DIR/test_${test_name}.log"
            
            echo -e "### $test_name ($result)\n" >> "$report_file"
            echo -e "```" >> "$report_file"
            if [ -f "$log_file" ]; then
                cat "$log_file" >> "$report_file"
            else
                echo "Log file not found" >> "$report_file"
            fi
            echo -e "```\n" >> "$report_file"
        done
    fi
    
    echo -e "${GREEN}[✓] Test report generated: $report_file${NC}"
    
    # Print summary to console
    echo -e "${BLUE}=== Test Summary ===${NC}"
    echo -e "Total Tests: $total_tests"
    echo -e "Passed: ${GREEN}$passed_tests${NC}"
    if [ $failed_tests -gt 0 ]; then
        echo -e "Failed: ${RED}$failed_tests${NC}"
    else
        echo -e "Failed: $failed_tests"
    fi
    if [ $timeout_tests -gt 0 ]; then
        echo -e "Timeouts: ${YELLOW}$timeout_tests${NC}"
    else
        echo -e "Timeouts: $timeout_tests"
    fi
    echo -e "Pass Rate: ${BLUE}$pass_percentage%${NC}"
    echo -e "${BLUE}===================${NC}"
}

# Main function
main() {
    # Parse command line arguments
    local test_to_run="all"
    if [ $# -gt 0 ]; then
        test_to_run="$1"
    fi
    
    # Initialize test environment
    init_test_env
    
    # Run specified test
    case "$test_to_run" in
        "core")
            test_core
            ;;
        "utils")
            test_utils
            ;;
        "install")
            test_install
            ;;
        "gpg")
            test_gpg
            ;;
        "cli")
            test_cli
            ;;
        "logging")
            test_logging
            ;;
        "main")
            test_main_cli
            ;;
        "dry-run")
            test_dry_run_install
            ;;
        "integration")
            test_integration
            ;;
        "all")
            run_all_tests
            ;;
        *)
            echo -e "${RED}[!] Unknown test: $test_to_run${NC}"
            echo -e "Available tests: core, utils, install, gpg, cli, logging, main, dry-run, integration, all"
            cleanup_test_env
            exit 1
            ;;
    esac
    
    # Generate test report
    generate_test_report
    
    # Clean up test environment
    cleanup_test_env
    
    # Return success if all tests passed
    if [ $(grep -l "FAIL" "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l) -eq 0 ] && [ $(grep -l "TIMEOUT" "$TEST_RESULTS_DIR"/*.result 2>/dev/null | wc -l) -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Run main function
main "$@"
