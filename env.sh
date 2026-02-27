# SPDX-FileCopyrightText: 2020 Efabless Corporation
# SPDX-License-Identifier: Apache-2.0
#
# Environment setup for Caravel user project (RTL-to-GDS, verification, precheck).
# Source this file in your shell before running make or other EDA flows:
#
#   source env.sh
#   # or with a specific PDK:
#   source env.sh sky130B
#
# Usage: source env.sh [sky130A|sky130B]

if [ -z "$BASH_SOURCE" ]; then
  echo "env.sh: Must be sourced from bash (e.g. source env.sh)." >&2
  return 2 2>/dev/null || exit 2
fi

# Project root (directory containing this script)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export UPRJ_ROOT="${UPRJ_ROOT:-$_SCRIPT_DIR}"
export CUP_ROOT="${CUP_ROOT:-$UPRJ_ROOT}"
export PROJECT_ROOT="$CUP_ROOT"

# PDK variant (optional first argument)
if [ -n "$1" ]; then
  case "$1" in
    sky130A|sky130B) export PDK="$1" ;;
    *) echo "env.sh: Unknown PDK '$1'; use sky130A or sky130B." >&2 ;;
  esac
fi
export PDK="${PDK:-sky130A}"

# Paths installed by `make setup` (relative to project root)
export CARAVEL_ROOT="${CARAVEL_ROOT:-$UPRJ_ROOT/caravel}"
export MCW_ROOT="${MCW_ROOT:-$UPRJ_ROOT/mgmt_core_wrapper}"
export PDK_ROOT="${PDK_ROOT:-$UPRJ_ROOT/dependencies/pdks}"
export OPENLANE_ROOT="${OPENLANE_ROOT:-$UPRJ_ROOT/dependencies/openlane_src}"
export TIMING_ROOT="${TIMING_ROOT:-$UPRJ_ROOT/dependencies/timing-scripts}"

# Derived
export PDKPATH="${PDK_ROOT}/${PDK}"

# Precheck (optional; default $HOME/mpw_precheck)
export PRECHECK_ROOT="${PRECHECK_ROOT:-$HOME/mpw_precheck}"

# PDK/LibreLane
export CIEL_DATA_SOURCE="${CIEL_DATA_SOURCE:-static-web:https://chipfoundry.github.io/ciel-releases}"
export DISABLE_LVS="${DISABLE_LVS:-0}"

# For verilog/dv (cocotb, make verify): same as project root
export TARGET_PATH="$UPRJ_ROOT"

# Optional: RV32I toolchain path for local DV (no Docker).
# Set before sourcing if you use a local toolchain, e.g.:
#   export GCC_PATH=/path/to/riscv-gnu-toolchain-rv32i
#   source env.sh
# export GCC_PATH="${GCC_PATH:-}"

# Ensure we're on PATH for convenience (no change if already present)
_path_add() {
  local d="$1"
  [ -z "$d" ] || [ ! -d "$d" ] && return
  case ":$PATH:" in
    *":$d:"*) ;;
    *) export PATH="$d:$PATH" ;;
  esac
}
_path_add "$UPRJ_ROOT/dependencies/timing-scripts/bin"

# Clean up helper used only in this script
unset _SCRIPT_DIR _path_add

echo "Environment loaded for Caravel user project (PDK=$PDK)"
echo "  UPRJ_ROOT=$UPRJ_ROOT"
echo "  PDK_ROOT=$PDK_ROOT"
echo "  CARAVEL_ROOT=$CARAVEL_ROOT"
echo "  OPENLANE_ROOT=$OPENLANE_ROOT"
echo "Run 'DISABLE_DEPRECATED_MAKEFILE_PROMPT=1 make setup' if dependencies are not installed yet."
