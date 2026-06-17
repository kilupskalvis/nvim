#!/usr/bin/env bash
set -euo pipefail

# --- Output helpers ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1"
  exit 1
}

command_exists() { command -v "$1" &>/dev/null; }

# --- OS detection ---

detect_os() {
  case "$(uname -s)" in
  Darwin)
    OS="macos"
    PKG_MGR="brew"
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      ubuntu | debian | pop | linuxmint) PKG_MGR="apt" ;;
      fedora | rhel | centos | rocky | alma) PKG_MGR="dnf" ;;
      arch | manjaro | endeavouros) PKG_MGR="pacman" ;;
      *)
        # Check ID_LIKE as fallback
        case "${ID_LIKE:-}" in
        *debian*) PKG_MGR="apt" ;;
        *fedora* | *rhel*) PKG_MGR="dnf" ;;
        *arch*) PKG_MGR="pacman" ;;
        *) error "Unsupported Linux distribution: $ID" ;;
        esac
        ;;
      esac
      OS="linux"
    else
      error "Cannot detect Linux distribution (missing /etc/os-release)"
    fi
    ;;
  *)
    error "Unsupported operating system: $(uname -s)"
    ;;
  esac

  info "Detected: $OS ($PKG_MGR)"
}

# --- Package manager helpers ---

pkg_update() {
  case "$PKG_MGR" in
  apt) sudo apt-get update -qq ;;
  dnf) : ;; # dnf auto-refreshes
  pacman) sudo pacman -Sy --noconfirm ;;
  brew) brew update --quiet ;;
  esac
}

pkg_install() {
  case "$PKG_MGR" in
  brew) brew install "$@" ;;
  apt) sudo apt-get install -y -qq "$@" ;;
  dnf) sudo dnf install -y -q "$@" ;;
  pacman) sudo pacman -S --noconfirm --needed "$@" ;;
  esac
}

# --- Installers ---

ensure_homebrew() {
  if [[ "$OS" != "macos" ]]; then return; fi
  if command_exists brew; then
    success "Homebrew already installed"
    return
  fi
  warn "Homebrew is not installed."
  read -rp "Install Homebrew? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  else
    error "Homebrew is required on macOS. Aborting."
  fi
}

ensure_curl() {
  if command_exists curl; then
    success "curl already installed"
    return
  fi
  info "Installing curl..."
  pkg_install curl
}

ensure_unzip() {
  if command_exists unzip; then
    success "unzip already installed"
    return
  fi
  info "Installing unzip..."
  pkg_install unzip
}

ensure_tar() {
  if command_exists tar; then
    success "tar already installed"
    return
  fi
  info "Installing tar..."
  pkg_install tar
}

ensure_build_tools() {
  if command_exists cc || command_exists gcc; then
    success "C compiler already installed"
    return
  fi
  info "Installing build tools..."
  case "$PKG_MGR" in
  brew) xcode-select --install 2>/dev/null || true ;;
  apt) pkg_install build-essential ;;
  dnf) pkg_install gcc ;;
  pacman) pkg_install base-devel ;;
  esac
}

ensure_git() {
  if command_exists git; then
    success "git already installed"
    return
  fi
  info "Installing git..."
  pkg_install git
}

ensure_ripgrep() {
  if command_exists rg; then
    success "ripgrep already installed"
    return
  fi
  info "Installing ripgrep..."
  pkg_install ripgrep
}

ensure_fd() {
  if command_exists fd || command_exists fdfind; then
    success "fd already installed"
    return
  fi
  info "Installing fd..."
  case "$PKG_MGR" in
  brew | pacman) pkg_install fd ;;
  apt | dnf) pkg_install fd-find ;;
  esac
}


ensure_node() {
  if command_exists node && command_exists npm; then
    success "Node.js already installed"
    return
  fi
  info "Installing Node.js..."
  case "$PKG_MGR" in
  brew) pkg_install node ;;
  apt) pkg_install nodejs npm ;;
  dnf) pkg_install nodejs npm ;;
  pacman) pkg_install nodejs npm ;;
  esac
}

ensure_python() {
  if command_exists python3 && command_exists pip3; then
    success "Python 3 already installed"
    return
  fi
  info "Installing Python 3..."
  case "$PKG_MGR" in
  brew) pkg_install python3 ;;
  apt) pkg_install python3 python3-pip ;;
  dnf) pkg_install python3 python3-pip ;;
  pacman) pkg_install python python-pip ;;
  esac
}

ensure_go() {
  if command_exists go; then
    success "Go already installed"
    return
  fi
  info "Installing Go..."
  case "$PKG_MGR" in
  brew) pkg_install go ;;
  apt) pkg_install golang ;;
  dnf) pkg_install golang ;;
  pacman) pkg_install go ;;
  esac
}

ensure_rust() {
  if command_exists rustc && command_exists cargo; then
    success "Rust already installed"
    return
  fi
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "${CARGO_HOME:-$HOME/.cargo}/env"
}

ensure_npm_package() {
  local pkg="$1"
  if npm list -g "$pkg" &>/dev/null; then
    success "$pkg (npm) already installed"
    return
  fi
  info "Installing $pkg globally via npm..."
  npm install -g "$pkg"
}

check_neovim() {
  if ! command_exists nvim; then
    warn "Neovim is not installed. Please install Neovim >= 0.10.0"
    warn "See: https://github.com/neovim/neovim/blob/master/INSTALL.md"
    return
  fi
  local version
  version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  local minor
  minor=$(echo "$version" | cut -d. -f2)
  if ((minor < 10)); then
    warn "Neovim $version found, but >= 0.10.0 is recommended for LazyVim"
  else
    success "Neovim $version"
  fi
}

# --- Smoke test ---

smoke_test() {
  echo ""
  info "Running smoke test..."

  local tools=("curl" "unzip" "tar" "git" "rg" "node" "npm" "python3" "go" "rustc" "cargo")
  local failed=0

  for tool in "${tools[@]}"; do
    if command_exists "$tool"; then
      success "$tool found"
    elif [[ "$tool" == "rg" ]] && command_exists rg; then
      success "$tool found"
    else
      warn "$tool NOT found"
      failed=1
    fi
  done

  # Also check fd/fdfind
  if command_exists fd || command_exists fdfind; then
    success "fd found"
  else
    warn "fd NOT found"
    failed=1
  fi

  # Check C compiler
  if command_exists cc || command_exists gcc; then
    success "C compiler found"
  else
    warn "C compiler NOT found"
    failed=1
  fi

  if ((failed)); then
    warn "Some tools are missing. Neovim may not work correctly."
  else
    success "All dependencies verified!"
  fi

  # Headless Neovim checks
  if command_exists nvim; then
    echo ""
    info "Testing Neovim plugin loading (this may take a moment)..."
    if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
      success "Plugins loaded successfully"
    else
      warn "Plugin sync had issues (this may resolve on next launch)"
    fi
  fi
}

# --- Main ---

main() {
  echo ""
  info "Neovim config dependency installer"
  echo ""

  detect_os

  if [[ "$OS" == "macos" ]]; then
    ensure_homebrew
  fi

  info "Updating package manager..."
  pkg_update

  ensure_curl
  ensure_unzip
  ensure_tar
  ensure_build_tools
  ensure_git
  ensure_ripgrep
  ensure_fd
  ensure_node
  ensure_python
  ensure_go
  ensure_rust
  ensure_npm_package prettier
  ensure_npm_package eslint

  echo ""
  check_neovim
  smoke_test

  echo ""
  success "Setup complete!"
  echo ""
}

main "$@"
