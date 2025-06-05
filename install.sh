#!/bin/bash
# Material You Dotfiles Installation Script
# Automated setup for Material You themed Wayland desktop

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script info
SCRIPT_NAME="Material You Dotfiles Installer"
VERSION="1.0.0"

echo -e "${PURPLE}
╔══════════════════════════════════════════════════════════════╗
║                 ${WHITE}Material You Dotfiles${PURPLE}                     ║
║              ${CYAN}Automated Installation Script${PURPLE}                 ║
║                      ${YELLOW}Version $VERSION${PURPLE}                        ║
╚══════════════════════════════════════════════════════════════╝
${NC}"

# Function to print colored status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/backup-$(date +%Y%m%d-%H%M%S)"
    print_info "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    local configs_to_backup=(
        "hypr"
        "waybar" 
        "rofi"
        "departure"
        "mako"
        "alacritty"
        "gtk-3.0"
        "gtk-4.0"
        "matugen"
        "fish"
    )
    
    for config in "${configs_to_backup[@]}"; do
        if [ -d "$HOME/.config/$config" ]; then
            print_info "Backing up $config..."
            cp -r "$HOME/.config/$config" "$backup_dir/" 2>/dev/null || true
        fi
    done
    
    print_status "Backup completed: $backup_dir"
}

# Function to check for required dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local required_deps=(
        "hyprland"
        "waybar"
        "rofi"
        "mako"
        "alacritty"
        "matugen"
        "swww"
    )
    
    local optional_deps=(
        "departure"
        "fish"
        "btop"
        "cava"
        "fastfetch"
    )
    
    local missing_required=()
    local missing_optional=()
    
    # Check required dependencies
    for dep in "${required_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_required+=("$dep")
        else
            print_status "$dep found"
        fi
    done
    
    # Check optional dependencies
    for dep in "${optional_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_optional+=("$dep")
        else
            print_status "$dep found (optional)"
        fi
    done
    
    # Report missing dependencies
    if [ ${#missing_required[@]} -ne 0 ]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_required[@]}"; do
            echo -e "  ${RED}✗${NC} $dep"
        done
        echo ""
        print_info "Install missing dependencies on Arch Linux:"
        echo -e "${CYAN}paru -S ${missing_required[*]}${NC}"
        echo ""
        read -p "Would you like to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled. Please install required dependencies first."
            exit 1
        fi
    fi
    
    if [ ${#missing_optional[@]} -ne 0 ]; then
        print_warning "Missing optional dependencies:"
        for dep in "${missing_optional[@]}"; do
            echo -e "  ${YELLOW}○${NC} $dep"
        done
        print_info "Optional packages can be installed later with:"
        echo -e "${CYAN}paru -S ${missing_optional[*]}${NC}"
        echo ""
    fi
}

# Function to install configurations
install_configs() {
    print_info "Installing configuration files..."
    
    # Ensure .config directory exists
    mkdir -p "$HOME/.config"
    
    # Copy all configuration directories
    if [ -d "config" ]; then
        print_info "Copying configuration files..."
        cp -r config/* "$HOME/.config/" 2>/dev/null || {
            print_error "Failed to copy configuration files"
            exit 1
        }
        print_status "Configuration files installed"
    else
        print_error "Config directory not found. Are you running this from the dotfiles directory?"
        exit 1
    fi
    
    # Make scripts executable
    if [ -d "$HOME/.config/hypr/scripts" ]; then
        print_info "Making scripts executable..."
        find "$HOME/.config/hypr/scripts" -name "*.sh" -exec chmod +x {} \;
        print_status "Scripts made executable"
    fi
    
    # Create wallpaper directory if it doesn't exist
    mkdir -p "$HOME/Pictures/Wallpapers"
    
    # Copy sample wallpapers if they exist
    if [ -d "assets/wallpapers" ]; then
        print_info "Installing sample wallpapers..."
        cp -r assets/wallpapers/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
        print_status "Sample wallpapers installed"
    else
        print_warning "No sample wallpapers found. Add your own to ~/Pictures/Wallpapers/"
    fi
}

# Function to set up systemd services
setup_services() {
    print_info "Setting up user services..."
    
    # Enable user services if they exist
    local services=(
        "mako"
    )
    
    for service in "${services[@]}"; do
        if systemctl --user list-unit-files | grep -q "$service.service"; then
            print_info "Enabling $service.service..."
            systemctl --user enable "$service.service" 2>/dev/null || true
        fi
    done
}

# Function to apply initial theme
apply_initial_theme() {
    print_info "Applying initial Material You theme..."
    
    if [ -x "$HOME/.config/hypr/scripts/pywal-random-theme.sh" ]; then
        print_info "Running theming script..."
        "$HOME/.config/hypr/scripts/pywal-random-theme.sh" || {
            print_warning "Initial theme application failed, but you can run it later"
        }
        print_status "Initial theme applied"
    else
        print_warning "Theming script not found or not executable"
    fi
}

# Function to show post-installation instructions
show_post_install() {
    echo -e "${GREEN}
╔══════════════════════════════════════════════════════════════╗
║                    ${WHITE}Installation Complete!${GREEN}                   ║
╚══════════════════════════════════════════════════════════════╝
${NC}"
    
    print_status "Material You dotfiles have been installed successfully!"
    echo ""
    print_info "Next steps:"
    echo -e "  ${CYAN}1.${NC} Log out and select Hyprland from your display manager"
    echo -e "  ${CYAN}2.${NC} Add wallpapers to: ${YELLOW}~/Pictures/Wallpapers/${NC}"
    echo -e "  ${CYAN}3.${NC} Apply themes with: ${YELLOW}~/.config/hypr/scripts/pywal-random-theme.sh${NC}"
    echo ""
    print_info "Key bindings:"
    echo -e "  ${CYAN}Super + D${NC}         - Open Rofi application launcher"
    echo -e "  ${CYAN}Super + Q${NC}         - Open Departure logout menu"
    echo -e "  ${CYAN}Super + Enter${NC}     - Open terminal"
    echo -e "  ${CYAN}Super + Shift + S${NC} - Screenshot"
    echo ""
    print_info "Troubleshooting:"
    echo -e "  ${CYAN}•${NC} If services don't start, try: ${YELLOW}systemctl --user restart mako${NC}"
    echo -e "  ${CYAN}•${NC} For theme issues, check: ${YELLOW}~/.config/hypr/scripts/pywal-random-theme.sh${NC}"
    echo -e "  ${CYAN}•${NC} Backup location: ${YELLOW}~/.config/backup-*${NC}"
    echo ""
    print_info "Enjoy your Material You desktop! 🎨"
}

# Main installation flow
main() {
    # Check if running in the right directory
    if [ ! -f "install.sh" ] || [ ! -d "config" ]; then
        print_error "Please run this script from the dotfiles directory"
        print_info "Usage: cd material-you-dotfiles && ./install.sh"
        exit 1
    fi
    
    # Check dependencies
    check_dependencies
    
    # Confirm installation
    echo ""
    print_warning "This will install Material You dotfiles to ~/.config/"
    print_info "Your existing configurations will be backed up"
    echo ""
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Backup existing configs
    backup_configs
    
    # Install configurations
    install_configs
    
    # Setup services
    setup_services
    
    # Apply initial theme
    apply_initial_theme
    
    # Show completion message
    show_post_install
}

# Run main function
main "$@"