#!/usr/bin/env bash
#
# Dotfiles installation script for Arch Linux + Hyprland
#

set -e

DOTFILES_DIR="${HOME}/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        error "GNU Stow is not installed!"
        echo "Install it with: sudo pacman -S stow"
        exit 1
    fi
    info "GNU Stow found"
}

# Install packages with stow
install_package() {
    local pkg=$1
    if [ -d "${DOTFILES_DIR}/${pkg}" ]; then
        info "Installing ${pkg}..."
        cd "${DOTFILES_DIR}" && stow "${pkg}"
    else
        warn "Package ${pkg} not found"
    fi
}

# Main
main() {
    info "Starting dotfiles installation..."
    
    check_stow
    
    echo ""
    echo "Available packages:"
    ls -1 "${DOTFILES_DIR}" | grep -v "^\." | grep -v "install.sh" | grep -v "README"
    echo ""
    
    read -p "Install all packages? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        info "Installing all packages..."
        cd "${DOTFILES_DIR}" && stow .
    else
        echo "Enter packages to install (space-separated), e.g.: hyprland waybar shell"
        read -p "Packages: " packages
        for pkg in $packages; do
            install_package "$pkg"
        done
    fi
    
    info "Installation complete!"
    echo ""
    echo "Note: You may need to restart your session or reload configs for changes to take effect."
}

main "$@"
