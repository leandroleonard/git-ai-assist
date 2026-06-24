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
SCRIPT_URL="$RAW_URL/git-ai-assist.sh"
VERSION="1.0.6"

# ===========================
# Helpers
# ===========================
info()    { echo -e "${GREEN}✓${NC} $1" >&2; }
warn()    { echo -e "${YELLOW}⚠${NC} $1" >&2; }
error()   { echo -e "${RED}✗${NC} $1" >&2; }
step()    { echo -e "${BLUE}▸${NC} $1" >&2; }
success() { echo -e "\n${GREEN}═══════════════════════════════════════${NC}" >&2; echo -e "${GREEN}  $1${NC}" >&2; echo -e "${GREEN}═══════════════════════════════════════${NC}\n" >&2; }

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
        info "Bash $bash_version ✓"
    fi

    # Check required commands
    local deps=("git" "curl" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            info "$dep installed ✓"
        else
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "" >&2
        warn "Missing dependencies: ${missing[*]}"
        echo "" >&2

        # Detect OS and suggest install command
        if command -v apt-get &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo apt-get install -y ${missing[*]}${NC}" >&2
        elif command -v dnf &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo dnf install -y ${missing[*]}${NC}" >&2
        elif command -v yum &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo yum install -y ${missing[*]}${NC}" >&2
        elif command -v pacman &>/dev/null; then
            echo -e "  Install with: ${CYAN}sudo pacman -S ${missing[*]}${NC}" >&2
        elif command -v brew &>/dev/null; then
            echo -e "  Install with: ${CYAN}brew install ${missing[*]}${NC}" >&2
        else
            echo -e "  Please install: ${CYAN}${missing[*]}${NC}" >&2
        fi
        echo "" >&2

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
    tmp_file=$(mktemp /tmp/git-ai-assist.XXXXXX.sh)

    # Try curl first, fallback to wget
    local download_ok=false
    if command -v curl &>/dev/null; then
        if curl -fsSL --connect-timeout 10 --max-time 30 "$SCRIPT_URL" -o "$tmp_file" 2>/dev/null; then
            download_ok=true
        fi
    fi

    if [ "$download_ok" = false ] && command -v wget &>/dev/null; then
        if wget -q --timeout=10 -O "$tmp_file" "$SCRIPT_URL" 2>/dev/null; then
            download_ok=true
        fi
    fi

    if [ "$download_ok" = false ]; then
        rm -f "$tmp_file"
        die "Failed to download script. Check your internet connection and repository URL: $SCRIPT_URL"
    fi

    # Verify downloaded file
    if [ ! -s "$tmp_file" ]; then
        rm -f "$tmp_file"
        die "Downloaded file is empty."
    fi

    # Verify it looks like a bash script
    if ! head -n1 "$tmp_file" | grep -q '^#!/bin/bash'; then
        rm -f "$tmp_file"
        die "Downloaded file is not a valid bash script."
    fi

    # Return ONLY the file path (stdout)
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
    if ! mv "$script_file" "$INSTALL_DIR/$SCRIPT_NAME"; then
        die "Failed to move script to $INSTALL_DIR/$SCRIPT_NAME"
    fi

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
    if echo "$PATH" | tr ':' '\n' | grep -q "^$INSTALL_DIR$"; then
        info "$INSTALL_DIR is already in PATH ✓"
        return 0
    fi

    warn "$INSTALL_DIR is not in your PATH"
    echo "" >&2

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
        echo -e "  Please add manually: ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}" >&2
        return 1
    fi

    step "Adding $INSTALL_DIR to PATH in $shell_rc..."

    # Check if already present in rc file
    if grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
        info "PATH already configured in $shell_rc ✓"
    else
        # Add to shell rc
        {
            echo ""
            echo "# Added by git-ai-assist installer on $(date)"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        } >> "$shell_rc"

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
    echo "" >&2
    success "git-ai-assist v$VERSION installed successfully!"
    echo -e "${BLUE}Next steps:${NC}" >&2
    echo "" >&2
    echo "  1. Initialize your project:" >&2
    echo -e "     ${CYAN}cd /seu/projeto${NC}" >&2
    echo -e "     ${CYAN}git-ai-assist init${NC}" >&2
    echo "" >&2
    echo "  2. Generate your first commit message:" >&2
    echo -e "     ${CYAN}git-ai-assist gen-commit${NC}" >&2
    echo "" >&2
    echo "  3. Generate a daily report:" >&2
    echo -e "     ${CYAN}git-ai-assist gen-report${NC}" >&2
    echo "" >&2
    echo "  4. View all commands:" >&2
    echo -e "     ${CYAN}git-ai-assist --help${NC}" >&2
    echo "" >&2
    echo -e "${YELLOW}Documentation: $REPO_URL${NC}" >&2
    echo "" >&2
}

# ===========================
# Main
# ===========================
main() {
    echo "" >&2
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}" >&2
    echo -e "${GREEN}║        Git AI Assistant Installer         ║${NC}" >&2
    echo -e "${GREEN}║           Version: $VERSION                  ║${NC}" >&2
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}" >&2
    echo "" >&2

    # Run installation steps
    check_existing
    check_requirements

    # Download script (capture ONLY stdout)
    local script_file
    script_file=$(download_script 2>/dev/null)

    # Install
    install_script "$script_file"
    setup_path
    verify_installation
    show_next_steps
}

# Run with error handling
main "$@" || {
    echo "" >&2
    error "Installation failed!"
    echo "" >&2
    echo "Troubleshooting:" >&2
    echo "  - Check your internet connection" >&2
    echo "  - Verify repository URL: $REPO_URL" >&2
    echo "  - Check permissions: $INSTALL_DIR" >&2
    echo "  - Manual install: See $REPO_URL/blob/main/README.md" >&2
    echo "" >&2
    exit 1
}