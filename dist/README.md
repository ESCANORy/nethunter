# NetHunter CLI - Advanced Installation Toolkit

![NetHunter Logo](https://www.kali.org/images/nethunter-logo.svg)

**Version:** 3.0 (May 2025)  
**Author:** Manus Team  
**License:** GPL-3.0

## Overview

NetHunter CLI is an advanced, modular toolkit for installing and managing Kali NetHunter in Termux environments. This toolkit provides a robust, secure, and highly customizable installation process with features like digital signature verification, dynamic image selection, comprehensive logging, and a full command-line interface.

## Features

- **Modular Architecture**: Clean separation of concerns with independent modules
- **Digital Signature Verification**: GPG signature verification for enhanced security
- **Dynamic Image Selection**: Automatically fetches and selects from available images
- **Comprehensive CLI**: Full command-line interface with support for all operations
- **Advanced Logging**: Detailed logging with system information and performance metrics
- **Automated Operation**: Support for non-interactive installation and updates
- **Backup and Restore**: Built-in functionality for backup and recovery
- **Integrity Checking**: Verification of script and download integrity
- **Configurable**: Extensive configuration options via JSON or command-line flags

## Installation

### Quick Install (One-Line Command)

```bash
curl -sL https://bit.ly/kali-nh-termux | bash
```

### Manual Installation

1. Download the toolkit:
   ```bash
   curl -sL https://github.com/kalilinux/nethunter-termux/archive/refs/heads/master.zip -o nethunter-cli.zip
   unzip nethunter-cli.zip
   cd nethunter-termux-master
   ```

2. Make the script executable:
   ```bash
   chmod +x nethunter-cli
   ```

3. Run the installer:
   ```bash
   ./nethunter-cli install
   ```

## Usage

### Basic Commands

```bash
# Install NetHunter with default settings
nethunter-cli install

# Install specific image type
nethunter-cli install --type minimal

# Update existing installation
nethunter-cli update

# Uninstall NetHunter
nethunter-cli uninstall

# Create backup
nethunter-cli backup

# Restore from backup
nethunter-cli restore

# Verify installation
nethunter-cli verify

# Show help
nethunter-cli help
```

### Advanced Options

```bash
# Install with specific architecture
nethunter-cli install --type minimal --arch arm64

# Install in non-interactive mode
nethunter-cli install --yes

# Install with custom directory
nethunter-cli install --dir ~/custom-nethunter

# Keep downloaded archive after installation
nethunter-cli install --keep-archive

# Force operation without confirmation
nethunter-cli update --force

# Run in quiet mode
nethunter-cli install --quiet

# Run in verbose mode
nethunter-cli install --verbose

# Disable colored output
nethunter-cli install --no-color
```

## Image Types

| Type | Description | Size | Recommended For |
|------|-------------|------|-----------------|
| full | Complete Kali NetHunter with all tools | ~2.1GB | Full penetration testing |
| minimal | Basic Kali NetHunter with essential tools | ~130MB | Limited storage devices |
| nano | Minimal installation with core functionality | ~180MB | Very limited storage or testing |

## Architecture Support

- **arm64**: Modern 64-bit ARM devices (most Android phones/tablets)
- **armhf**: 32-bit ARM devices (older Android devices)
- **amd64**: 64-bit x86 devices (Android-x86 on PC/laptop)
- **i386**: 32-bit x86 devices (older Android-x86 installations)

## Configuration

The toolkit uses a JSON configuration file located at `~/.nethunter/config.json`. This file is created automatically on first run but can be modified manually for advanced customization.

Example configuration:

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

## Logging

The toolkit maintains detailed logs of all operations in `~/.nethunter/logs/`. These logs include:

- System information
- Command execution details
- Performance metrics
- Error reports
- Installation summaries

Logs are automatically rotated to prevent excessive disk usage.

### Crash Reports

In case of errors, crash reports are generated in `~/.nethunter/logs/crashes/`. These reports contain detailed information about the error and system state, which can be helpful for troubleshooting.

## Security Features

### Digital Signature Verification

The toolkit can verify the authenticity of scripts and downloads using GPG signatures. The public key is included in the distribution and automatically imported during installation.

### Integrity Checking

File integrity is verified using SHA-256 hashes to ensure downloads are not corrupted or tampered with.

### Least Privilege Principle

The toolkit is designed to run with minimal privileges and will refuse to run as root for security reasons.

## Troubleshooting

### Common Issues

#### Installation Fails with "Not enough space"

Ensure you have sufficient storage space available. The full image requires approximately 3GB of free space.

```bash
# Check available space
df -h

# Try installing a smaller image
nethunter-cli install --type minimal
```

#### "Command not found" After Installation

The aliases may not be loaded. Try:

```bash
source ~/.bashrc
# or
source ~/.profile
```

#### Cannot Connect to Internet from NetHunter

Check your network configuration and ensure Termux has internet permissions.

```bash
# Test connectivity in Termux
ping -c 1 8.8.8.8

# Test DNS resolution
nslookup kali.org
```

#### GPG Verification Failed

This could indicate tampering or a corrupted download. Try reinstalling from the official source.

```bash
# Force reinstall with integrity check
nethunter-cli install --force
```

### Log Analysis

Logs can be helpful for diagnosing issues:

```bash
# View the latest log
cat $(ls -t ~/.nethunter/logs/*.log | head -1)

# Search logs for errors
grep ERROR ~/.nethunter/logs/*.log
```

## Development

### Modular Architecture

The toolkit is organized into the following modules:

- **core.sh**: Core functions and variables
- **utils.sh**: Utility functions
- **install.sh**: Installation functions
- **gpg.sh**: GPG signature verification functions
- **cli.sh**: Command-line interface functions
- **logging.sh**: Enhanced logging functions

### Adding New Features

To add new features, create a new module or extend an existing one. Ensure your code follows the existing patterns and includes proper logging and error handling.

### Testing

The toolkit includes a test framework for verifying functionality:

```bash
# Run all tests
./test.sh

# Run specific test
./test.sh install
```

### Building from Source

To build the toolkit from source:

```bash
# Clone the repository
git clone https://github.com/kalilinux/nethunter-termux.git
cd nethunter-termux

# Install development dependencies
pkg install jq gpg

# Build the package
./build.sh
```

## Integration

### CI/CD Integration

The toolkit can be integrated into CI/CD pipelines using the non-interactive mode:

```bash
nethunter-cli install --yes --type minimal --quiet
```

### Webhook Integration

For remote monitoring, configure a webhook URL in the configuration file:

```json
{
  "webhook_url": "https://example.com/webhook"
}
```

Logs and crash reports will be automatically sent to this URL.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

Please ensure your code follows the project's coding standards and includes appropriate documentation.

## License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

## Acknowledgments

- Kali Linux team for NetHunter
- Termux developers
- All contributors to the project

---

*This toolkit is not officially affiliated with Kali Linux or Termux unless otherwise stated.*
