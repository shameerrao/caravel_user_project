#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Install system and Python dependencies for this Caravel user project.
# Supports Linux (Debian/Ubuntu with apt). On macOS/Windows, install Python 3.8+
# and Docker manually, then run: pip install -r requirements.txt
#
# Usage:
#   ./scripts/install_requirements.sh
#   ./scripts/install_requirements.sh --venv   # create and use a venv in ./venv

set -e

USE_VENV=
while [ -n "$1" ]; do
  case "$1" in
    --venv) USE_VENV=1 ;;
    -h|--help)
      echo "Usage: $0 [--venv]"
      echo "  --venv   Create and use a virtualenv in ./venv (recommended)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Caravel user project: install requirements ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# --- System packages (Linux with apt) ---
if command -v apt-get &>/dev/null; then
  echo "Installing system packages (sudo may prompt)..."
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-tk \
    git
  echo "System packages OK."
else
  echo "No apt-get found; skipping system packages."
  echo "Ensure Python 3.8+ and pip are installed (e.g. from python.org or Homebrew)."
fi
echo ""

# --- Python: venv or user ---
if [ -n "$USE_VENV" ]; then
  if [ ! -d "venv" ]; then
    echo "Creating virtualenv in ./venv ..."
    python3 -m venv venv
  fi
  echo "Activating venv and installing Python dependencies..."
  # shellcheck source=/dev/null
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  echo "Python deps (venv) OK. Activate with: source venv/bin/activate"
else
  echo "Installing Python dependencies (user site)..."
  pip3 install --user --upgrade pip
  pip3 install --user -r requirements.txt
  echo "Python deps OK."
fi
echo ""

# --- Docker check ---
if command -v docker &>/dev/null; then
  echo "Docker: $(docker --version)"
else
  echo "Docker not found. Install it for hardening and precheck:"
  echo "  https://docs.docker.com/get-docker/"
fi
echo ""

# --- Next steps ---
echo "=== Next steps ==="
echo "1. Initialize project:  cf init"
echo "2. Setup PDK/OpenLane: cf setup"
echo "3. Source environment: source env.sh"
echo "4. (Optional) Configure GPIO: cf gpio-config"
echo ""
echo "Then run hardening, verification, or precheck as needed."
