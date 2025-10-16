#!/bin/bash
# TLP Power Profiles - Installation Script
# Installs TLP configuration files and profile manager script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root${NC}"
    echo "Run it as your regular user. It will ask for sudo when needed."
    exit 1
fi

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if TLP is installed
check_tlp() {
    if ! command -v tlp &> /dev/null; then
        print_error "TLP is not installed"
        echo "Install TLP with: sudo apt install tlp tlp-rdw"
        exit 1
    fi
    print_success "TLP is installed"
}

# Check for conflicting services
check_conflicts() {
    if systemctl is-active --quiet power-profiles-daemon; then
        print_warning "power-profiles-daemon is running (conflicts with TLP)"
        echo "This service conflicts with TLP EPP settings."
        read -p "Stop and disable power-profiles-daemon? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl stop power-profiles-daemon
            sudo systemctl disable power-profiles-daemon
            sudo systemctl mask power-profiles-daemon
            print_success "power-profiles-daemon disabled"
        else
            print_warning "Continuing with power-profiles-daemon enabled (may cause issues)"
        fi
    else
        print_success "No conflicting services detected"
    fi
}

# Backup existing configuration
backup_config() {
    local backup_file="/etc/tlp.conf.backup-$(date +%Y%m%d-%H%M%S)"

    if [ -f "/etc/tlp.conf" ]; then
        sudo cp /etc/tlp.conf "$backup_file"
        print_success "Backed up /etc/tlp.conf to $backup_file"
    fi
}

# Install main configuration
install_main_config() {
    if [ -f "$SCRIPT_DIR/configs/tlp.conf" ]; then
        sudo cp "$SCRIPT_DIR/configs/tlp.conf" /etc/tlp.conf
        print_success "Installed /etc/tlp.conf"
    else
        print_error "Source file not found: $SCRIPT_DIR/configs/tlp.conf"
        exit 1
    fi
}

# Install profile configurations
install_profiles() {
    local profile_dir="$SCRIPT_DIR/configs/tlp.d"

    if [ ! -d "$profile_dir" ]; then
        print_error "Profile directory not found: $profile_dir"
        exit 1
    fi

    # Copy all profile files
    for profile in "$profile_dir"/*.disabled; do
        if [ -f "$profile" ]; then
            sudo cp "$profile" /etc/tlp.d/
            print_success "Installed $(basename "$profile")"
        fi
    done

    # Activate balanced profile by default
    if [ -f "/etc/tlp.d/90-perfil-balanceado.conf.disabled" ]; then
        sudo mv /etc/tlp.d/90-perfil-balanceado.conf.disabled \
                /etc/tlp.d/90-perfil-balanceado.conf
        print_success "Activated balanced profile as default"
    fi
}

# Install tlp-perfil script
install_script() {
    local script_file="$SCRIPT_DIR/scripts/tlp-perfil"
    local install_dir="$HOME/.local/bin"

    if [ ! -f "$script_file" ]; then
        print_error "Script not found: $script_file"
        exit 1
    fi

    # Create directory if it doesn't exist
    mkdir -p "$install_dir"

    # Copy and make executable
    cp "$script_file" "$install_dir/tlp-perfil"
    chmod +x "$install_dir/tlp-perfil"

    print_success "Installed tlp-perfil to $install_dir"

    # Check if directory is in PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        print_warning "$install_dir is not in your PATH"
        echo "Add this line to your ~/.bashrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        read -p "Add to ~/.bashrc automatically? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            print_success "Added to ~/.bashrc (restart terminal or run: source ~/.bashrc)"
        fi
    fi
}

# Apply TLP configuration
apply_config() {
    print_section "Applying TLP Configuration"

    # Enable TLP service if not enabled
    if ! systemctl is-enabled --quiet tlp.service; then
        sudo systemctl enable tlp.service
        print_success "Enabled TLP service"
    fi

    # Start TLP
    sudo tlp start
    print_success "TLP configuration applied"
}

# Verify installation
verify_installation() {
    print_section "Verifying Installation"

    # Check if tlp-perfil is accessible
    if command -v tlp-perfil &> /dev/null; then
        print_success "tlp-perfil command is available"
    else
        print_warning "tlp-perfil not in PATH (restart terminal)"
    fi

    # Check active profile
    if [ -f "/etc/tlp.d/90-perfil-balanceado.conf" ]; then
        print_success "Balanced profile is active"
    fi

    # Check hardware settings
    local epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "N/A")
    local turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || echo "N/A")
    local cpu_max=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "N/A")

    echo ""
    echo "Current hardware settings:"
    echo "  CPU EPP:    $epp"
    echo "  CPU Turbo:  $([ "$turbo" = "1" ] && echo "OFF" || echo "ON")"
    echo "  CPU Max:    ${cpu_max}%"
}

# Show post-installation instructions
show_instructions() {
    print_section "Installation Complete"

    echo ""
    echo "TLP Power Profiles has been installed successfully!"
    echo ""
    echo "Usage:"
    echo "  tlp-perfil status       - Show current profile and settings"
    echo "  tlp-perfil balanceado   - Switch to balanced profile (default)"
    echo "  tlp-perfil economia     - Switch to economy profile (max battery)"
    echo "  tlp-perfil performance  - Switch to performance profile (max speed)"
    echo ""
    echo "Profiles:"
    echo "  Balanceado:  ~25-30% more battery, nearly imperceptible slowdown"
    echo "  Economia:    ~50-60% more battery, noticeable slowdown"
    echo "  Performance: Maximum speed, reduced battery life"
    echo ""
    echo "Documentation:"
    echo "  README:          $SCRIPT_DIR/README.md"
    echo "  Testing:         $SCRIPT_DIR/docs/TESTING.md"
    echo "  Technical:       $SCRIPT_DIR/docs/TECHNICAL.md"
    echo "  Troubleshooting: $SCRIPT_DIR/docs/TROUBLESHOOTING.md"
    echo ""
    echo "If tlp-perfil command is not found, restart your terminal or run:"
    echo "  source ~/.bashrc"
    echo ""
}

# Uninstall function
uninstall() {
    print_section "Uninstalling TLP Power Profiles"

    # Find most recent backup
    local latest_backup=$(ls -t /etc/tlp.conf.backup-* 2>/dev/null | head -1)

    if [ -n "$latest_backup" ]; then
        echo "Found backup: $latest_backup"
        read -p "Restore this backup? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo cp "$latest_backup" /etc/tlp.conf
            print_success "Restored backup"
        fi
    else
        print_warning "No backup found in /etc/"
    fi

    # Remove profile files
    sudo rm -f /etc/tlp.d/90-perfil-*.conf*
    print_success "Removed profile configurations"

    # Remove script
    rm -f "$HOME/.local/bin/tlp-perfil"
    print_success "Removed tlp-perfil script"

    # Restart TLP
    sudo systemctl restart tlp.service
    print_success "Restarted TLP service"

    echo ""
    echo "Uninstallation complete!"
}

# Main installation flow
main() {
    if [ "$1" = "--uninstall" ]; then
        uninstall
        exit 0
    fi

    print_section "TLP Power Profiles - Installation"
    echo "This will install optimized TLP configurations and profile manager."
    echo "Your existing TLP configuration will be backed up."
    echo ""
    read -p "Continue with installation? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi

    print_section "Checking Prerequisites"
    check_tlp
    check_conflicts

    print_section "Installing Configuration Files"
    backup_config
    install_main_config
    install_profiles

    print_section "Installing Profile Manager Script"
    install_script

    apply_config
    verify_installation
    show_instructions
}

# Run main function
main "$@"
