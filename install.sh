#!/bin/bash

# ============================================================
# git-ai-assist — Install Script
# Usage: curl -fsSL https://raw.githubusercontent.com/leandroleonard/git-ai-assist/main/install.sh | bash
# ============================================================

set -euo pipefail

# ===========================
# Colors
# ===========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===========================
# Config
# ===========================
REPO_URL="https://github.com/leandroleonard/git-ai-assist"
RAW_URL="https://raw.githubusercontent.com/leandroleonard/git-ai-assist/main"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="git-ai-assist"
SCRIPT_URL="$RAW_URL/$SCRIPT_NAME.sh"
VERSION="1.0.0"

# ===========================
# Helpers
# ===========================
info()    { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; }
step()    { echo -e "${BLUE}▸${NC} $1"; }
success() { echo -e "\n${GREEN}═══════════════════════════════════════${NC}"; echo -e "${GREEN}  $1${NC}"; echo -e "${GREEN}═══════════════════════════════════════${NC}\n"; }

die() {
    error "$1"
    exit 1
}

# ===========================
# Check existing installation
# ===========================
check_existing() {
    if command -v "$SCRIPT_NAME" &>/dev/null; then
        local existing_path
        existing_path=$(command -v "$SCRIPT_NAME")
        warn "$SCRIPT_NAME is already installed at: $existing_path"
        read -rp "Do you want to reinstall/upgrade? (y/n) [y]: " reinstall
        if [[ "$reinstall" == "n" || "$reinstall" == "N" ]]; then
            info "Keeping existing installation."
            exit 0
        fi
        info "Reinstalling..."
    fi
}

# ===========================
# Check system requirements
# ===========================
check_requirements() {
    step "Checking system requirements..."

    # Check bash version
    local bash_version
    bash_version=$(bash --version | head -n1 | grep -oP '\d+\.\d+' | head -1)
    if [[ $(echo "$bash_version 4.0" | awk '{if ($1 >= $2) print "ok"; else print "fail"}') != "ok" ]]; then
        warn "Bash version < 4.0 detected. Some features may not work."
    else
        info "Bash $(bash --version | head -n1 | grep -oP '\d+\.\d+' | head -1) ✓"
    fi

    # Check required commands
    local deps=("git" "curl" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            info "$dep $(eval "$dep --version 2>/dev/null | head -n1 || echo 'installed'") ✓"
        else
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        warn "Missing dependencies: ${missing[*]}"
        echo ""

        # Detect OS and suggest install command
        if command -v apt-get &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo apt-get install -y ${missing[*]}${NC}"
        elif command -v dnf &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo dnf install -y ${missing[*]}${NC}"
        elif command -v yum &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo yum install -y ${missing[*]}${NC}"
        elif command -v pacman &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo pacman -S ${missing[*]}${NC}"
        elif command -v brew &>/dev/null; then
            echo -e "  Install with: ${CYAN}brew install ${missing[*]}${NC}"
        else
            echo -e "  Please install: ${CYAN}${missing[*]}${NC}"
        fi
        echo ""

        read -rp "Do you want to install missing dependencies automatically? (y/n) [y]: " install_deps
        if [[ "$install_deps" != "n" && "$install_deps" != "N" ]]; then
            step "Installing dependencies..."
            if command -v apt-get &>/dev/null; then
                sudo apt-get install -y "${missing[@]}" || die "Failed to install dependencies. Please install them manually."
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y "${missing[@]}" || die "Failed to install dependencies. Please install them manually."
            elif command -v yum &>/dev/null; then
                sudo yum install -y "${missing[@]}" || die "Failed to install dependencies. Please install them manually."
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm "${missing[@]}" || die "Failed to install dependencies. Please install them manually."
            elif command -v brew &>/dev/null; then
                brew install "${missing[@]}" || die "Failed to install dependencies. Please install them manually."
            else
                die "Cannot auto-install dependencies. Please install them manually."
            fi
            info "Dependencies installed successfully!"
        else
            die "Cannot proceed without required dependencies."
        fi
    fi
}

# ===========================
# Download script
# ===========================
download_script() {
    step "Downloading $SCRIPT_NAME from GitHub..."

    local tmp_file
    tmp_file=$(mktemp)

    # Try curl first, fallback to wget
    if command -v curl &>/dev/null; then
        if ! curl -fsSL --connect-timeout 10 --max-time 30 "$SCRIPT_URL" -o "$tmp_file" 2>/dev/null; then
            # Try alternative URL (release)
            if ! curl -fsSL --connect-timeout 10 --max-time 30 "$REPO_URL/releases/latest/download/$SCRIPT_NAME.sh" -o "$tmp_file" 2>/dev/null; then
                die "Failed to download script. Check your internet connection and repository URL."
            fi
        fi
    elif command -v wget &>/dev/null; then
        if ! wget -q --timeout=10 -O "$tmp_file" "$SCRIPT_URL" 2>/dev/null; then
            die "Failed to download script. Check your internet connection and repository URL."
        fi
    else
        die "Neither curl nor wget is available."
    fi

    # Verify downloaded file
    if [ ! -s "$tmp_file" ]; then
        die "Downloaded file is empty."
    fi

    # Verify it looks like a bash script
    if ! head -n1 "$tmp_file" | grep -q '^#!/bin/bash'; then
        die "Downloaded file is not a valid bash script."
    fi

    echo "$tmp_file"
}

# ===========================
# Install script
# ===========================
install_script() {
    local script_file="$1"

    step "Installing to $INSTALL_DIR/$SCRIPT_NAME..."

    # Create install directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"

    # Move script to install location
    mv "$script_file" "$INSTALL_DIR/$SCRIPT_NAME"

    # Make executable
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

    info "Installed to: $INSTALL_DIR/$SCRIPT_NAME"
}

# ===========================
# Setup PATH
# ===========================
setup_path() {
    step "Checking PATH configuration..."

    # Check if install directory is already in PATH
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        info "$INSTALL_DIR is already in PATH ✓"
        return 0
    fi

    warn "$INSTALL_DIR is not in your PATH"
    echo ""

    # Detect shell
    local shell_name
    shell_name=$(basename "$SHELL")
    local shell_rc=""

    case "$shell_name" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                shell_rc="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                shell_rc="$HOME/.bash_profile"
            elif [ -f "$HOME/.profile" ]; then
                shell_rc="$HOME/.profile"
            fi
            ;;
        zsh)
            if [ -f "$HOME/.zshrc" ]; then
                shell_rc="$HOME/.zshrc"
            elif [ -f "$HOME/.zprofile" ]; then
                shell_rc="$HOME/.zprofile"
            fi
            ;;
        fish)
            shell_rc="$HOME/.config/fish/config.fish"
            ;;
    esac

    if [ -z "$shell_rc" ]; then
        warn "Could not detect shell config file."
        echo -e "  Please add manually: ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
        return 1
    fi

    step "Adding $INSTALL_DIR to PATH in $shell_rc..."

    # Check if already present in rc file
    if grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
        info "PATH already configured in $shell_rc ✓"
    else
        # Add to shell rc
        echo "" >> "$shell_rc"
        echo "# Added by git-ai-assist installer on $(date)" >> "$shell_rc"
        
        case "$shell_name" in
            fish)
                echo "fish_add_path $INSTALL_DIR" >> "$shell_rc"
                ;;
            *)
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_rc"
                ;;
        esac

        info "PATH added to $shell_rc ✓"
    fi

    # Add to current session
    export PATH="$INSTALL_DIR:$PATH"
    info "PATH updated for current session ✓"
}

# ===========================
# Verify installation
# ===========================
verify_installation() {
    step "Verifying installation..."

    if ! command -v "$SCRIPT_NAME" &>/dev/null; then
        die "Installation verification failed. $SCRIPT_NAME not found in PATH."
    fi

    local installed_version
    installed_version=$("$SCRIPT_NAME" --version 2>/dev/null || echo "unknown")

    info "Version: $installed_version ✓"
    info "Location: $(command -v "$SCRIPT_NAME") ✓"
}

# ===========================
# Show next steps
# ===========================
show_next_steps() {
    echo ""
    success "git-ai-assist v$VERSION installed successfully!"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "  1. Initialize your project:"
    echo -e "     ${CYAN}cd /seu/projeto${NC}"
    echo -e "     ${CYAN}git-ai-assist init${NC}"
    echo ""
    echo "  2. Generate your first commit message:"
    echo -e "     ${CYAN}git-ai-assist gen-commit${NC}"
    echo ""
    echo "  3. Generate a daily report:"
    echo -e "     ${CYAN}git-ai-assist gen-report${NC}"
    echo ""
    echo "  4. View all commands:"
    echo -e "     ${CYAN}git-ai-assist --help${NC}"
    echo ""
    echo -e "${YELLOW} Documentation: $REPO_URL${NC}"
    echo ""
}

# ===========================
# Main
# ===========================
main() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          Git AI Assistant Installer       ║${NC}"
    echo -e "${GREEN}║           Version: $VERSION               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""

    # Run installation steps
    check_existing
    check_requirements

    local script_file
    script_file=$(download_script)

    install_script "$script_file"
    setup_path
    verify_installation
    show_next_steps
}

# Run with error handling
main "$@" || {
    echo ""
    error "Installation failed!"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check your internet connection"
    echo "  - Verify repository URL: $REPO_URL"
    echo "  - Check permissions: $INSTALL_DIR"
    echo "  - Manual install: See $REPO_URL/blob/main/README.md"
    echo ""
    exit 1
}