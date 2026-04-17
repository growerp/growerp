#!/usr/bin/env bash
# setup-flutter.sh
# Performs one-time setup steps required before running Flutter on Linux.
#
# Run once after cloning and running 'melos bootstrap':
#   cd growerp/flutter
#   bash setup-flutter.sh
#
# This script is also called automatically by 'melos bootstrap' via the
# postBootstrap hook defined in pubspec.yaml.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ─── gtk FFI bindings ─────────────────────────────────────────────────────────
# The gtk pub package (used by Flutter Linux) ships without its generated FFI
# binding file (libgtk.g.dart). It must be generated locally using ffigen
# against the system's GTK 3 development headers.
#
# Required system packages (Debian/Ubuntu):
#   sudo apt-get install -y libgtk-3-dev libclang-dev

generate_gtk_bindings() {
  local GTK_PKG=""
  if [ -d "$HOME/.pub-cache/hosted/pub.dev" ]; then
    GTK_PKG="$(find "$HOME/.pub-cache/hosted/pub.dev" -maxdepth 1 -name "gtk-*" -type d | sort -V | tail -1)"
  fi

  if [ -z "$GTK_PKG" ]; then
    warning "gtk package not found in pub cache — skipping FFI generation."
    warning "Run 'flutter pub get' in a package that depends on gtk first."
    return 0
  fi

  local BINDING="$GTK_PKG/lib/src/libgtk.g.dart"
  local GTK_VERSION
  GTK_VERSION="$(basename "$GTK_PKG")"

  if [ -f "$BINDING" ]; then
    info "gtk FFI bindings already exist for $GTK_VERSION — skipping."
    return 0
  fi

  info "Generating GTK FFI bindings for $GTK_VERSION ..."

  # Check for required GTK headers
  if [ ! -f "/usr/include/gtk-3.0/gtk/gtk.h" ]; then
    error "GTK 3 development headers not found."
    error "Install them with: sudo apt-get install -y libgtk-3-dev libclang-dev"
    exit 1
  fi

  local TMP_DIR
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  cp -r "$GTK_PKG" "$TMP_DIR/gtk"
  cd "$TMP_DIR/gtk"

  info "Running dart pub get in temp copy..."
  dart pub get --no-example 2>&1 | tail -3

  info "Running ffigen..."
  dart run ffigen --config ffigen.yaml 2>&1 | grep -E "^(Finished|ERROR|WARNING: Generated)" || true

  if [ ! -f "lib/src/libgtk.g.dart" ]; then
    error "ffigen did not produce lib/src/libgtk.g.dart"
    exit 1
  fi

  cp "lib/src/libgtk.g.dart" "$BINDING"
  success "GTK FFI bindings written to $BINDING"

  cd "$SCRIPT_DIR"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
info "Running Flutter one-time setup..."
generate_gtk_bindings
success "Flutter setup complete."
