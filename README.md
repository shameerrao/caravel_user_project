<div align="center">

<img src="https://umsousercontent.com/lib_lnlnuhLgkYnZdkSC/hj0vk05j0kemus1i.png" alt="ChipFoundry Logo" height="140" />

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Inter&size=44&duration=3000&pause=600&color=4C6EF5&center=true&vCenter=true&width=1100&lines=Caravel+User+Project+Template;OpenLane+%2B+ChipFoundry+Flow;Verification+and+Shuttle-Ready)](https://git.io/typing-svg)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![ChipFoundry Marketplace](https://img.shields.io/badge/ChipFoundry-Marketplace-6E40C9.svg)](https://platform.chipfoundry.io/marketplace)
[![CI](https://github.com/shameerrao/caravel_user_project/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/shameerrao/caravel_user_project/actions/workflows/user_project_ci.yml)

</div>

Students clone this repo and build from it. **No paths in this README point to instructor or server-specific locations.** Where you must set your own path or URL, it is called out in [Where to update paths](#where-to-update-paths) and in the relevant sections below.

## Table of Contents
- [Overview](#overview)
- [This Repository](#this-repository)
- [Student tapeout flow: every command](#student-tapeout-flow-every-command)
- [GitHub Actions (RTL-to-GDS Pipeline)](#github-actions-rtl-to-gds-pipeline)
- [GitHub self-hosted runner](#github-self-hosted-runner)
- [Documentation & Resources](#documentation--resources)
- [Prerequisites](#prerequisites)
- [Environment script (EDA tools)](#environment-script-eda-tools)
- [Project Structure](#project-structure)
- [Starting Your Project](#starting-your-project)
- [Development Flow](#development-flow)
- [GPIO Configuration](#gpio-configuration)
- [Local Precheck](#local-precheck)
- [Layout Diagram](#layout-diagram)
- [Where to update paths](#where-to-update-paths)
- [Checklist for Shuttle Submission](#checklist-for-shuttle-submission)

## Overview
This repository contains a user project designed for integration into the **Caravel chip user space**. Use it as a template for integrating custom RTL with Caravel's system-on-chip (SoC) utilities, including:

* **IO Pads:** Configurable general-purpose input/output.
* **Logic Analyzer Probes:** 128 signals for non-intrusive hardware debugging.
* **Wishbone Port:** A 32-bit standard bus interface for communication between the RISC-V management core and your custom hardware.

---

## Tapeout flow: Every Command

Use this section as a single reference for the full tapeout flow. Run from the **project root** unless noted. In new terminals, run **source env.sh** again (and activate your venv if you use one).

### 1. Get the repo and install dependencies

```bash
git clone https://github.com/shameerrao/caravel_user_project.git
cd caravel_user_project
```

**Install tools (pick one):**

```bash
# Use a virtualenv (recommended)
./scripts/install_requirements.sh --venv
source venv/bin/activate
```

Ensure **Docker** is installed and running ([install](https://docs.docker.com/get-docker/) if needed).

---

### 2. Source environment and one-time project setup

```bash
source env.sh
export DISABLE_DEPRECATED_MAKEFILE_PROMPT=1
make setup
```

- `source env.sh` — Sets `PDK_ROOT`, `CARAVEL_ROOT`, `OPENLANE_ROOT`, etc. Do this in every new shell.
- `DISABLE_DEPRECATED_MAKEFILE_PROMPT=1` — Allows Makefile setup targets to run non-interactively (CI-friendly).
- `make setup` — Installs Caravel (lite), management core wrapper, PDK, LibreLane/OpenLane, cocotb, precheck images.

---

### 3. Configure GPIO (required before sim and precheck)

```bash
source env.sh
python3 scripts/gpio_config.py --set-all GPIO_MODE_USER_STD_INPUT_NOPULL
```

This updates `verilog/rtl/user_defines.v` so GPIO 5–37 have valid power-on modes (required for sim and precheck).

---

### 4. Edit RTL and openlane config (your design work)

- RTL: edit `verilog/rtl/` (e.g. `user_proj_example.v`, `user_project_wrapper.v`).
- Macro config: add or edit `openlane/<macro_name>/config.json` (or `config.tcl`).
- Wire your macro into `verilog/rtl/user_project_wrapper.v` and point `openlane/user_project_wrapper/config.json` at its LEF/GDS/verilog.

No single command; edit files as needed.

---

### 5. Run simulation (make sim)

```bash
source env.sh
make verify-<test_name>-rtl        # One test, RTL
make verify-<test_name>-gl         # One test, gate-level
make verify-all-rtl                # All tests (RTL)
```

Examples: `make verify-io_ports-rtl`, `make verify-wb_port-rtl`, `make verify-all-rtl`. Run after GPIO config and after RTL changes.

---

### 6. Harden the design (RTL → GDS)

**Option A — one macro at a time:**

```bash
source env.sh
make -C openlane list              # List designs
make user_proj_example             # Harden a macro (runs LibreLane)
make user_project_wrapper          # Then the top wrapper
```

**Option B — full flow (all macros in dependency order):**

```bash
source env.sh
python3 .github/scripts/get_designs.py --design $(pwd)
for design in $(cat harden_sequence.txt); do [ -z "$design" ] && continue; make "$design" || exit 1; done
```

Outputs: `gds/`, `lef/`, `verilog/gl/`, `signoff/`.

---

### 7. Run precheck (shuttle readiness)

```bash
source env.sh
export DISABLE_DEPRECATED_MAKEFILE_PROMPT=1
make run-precheck
```

Run after hardening and after GPIO config. Optional: `DISABLE_LVS=1 make run-precheck`.

---

### 8. Optional: static timing analysis (STA)

```bash
source env.sh
make setup-timing-scripts   # Once if needed
make extract-parasitics
make create-spef-mapping
make caravel-sta
```

---

### Quick copy-paste sequence (after first-time setup)

Once clone and `make setup` are done:

```bash
source env.sh
python3 scripts/gpio_config.py --set-all GPIO_MODE_USER_STD_INPUT_NOPULL   # If not done yet
make verify-all-rtl                                                      # Sim
python3 .github/scripts/get_designs.py --design $(pwd)
for design in $(cat harden_sequence.txt); do [ -z "$design" ] && continue; make "$design" || exit 1; done
export DISABLE_DEPRECATED_MAKEFILE_PROMPT=1
make run-precheck
```

---

## GitHub Actions (RTL-to-GDS Pipeline)
A single workflow runs the full SkyWater 130 flow: [**CI**](.github/workflows/user_project_ci.yml) (`.github/workflows/user_project_ci.yml`). The structure mirrors a typical Caravel tapeout CI: **Init** → **sim-rtl** (RTL verification) → **hardening** (RTL→GDS) → **precheck** → **Collect logs on failure**.

| Runner | Trigger | What it does |
|--------|---------|--------------|
| `ubuntu-latest` (default) or [self-hosted](#github-self-hosted-runner) | Every push/PR, or **Run workflow** in Actions | **sim-rtl** (RTL sim for sky130A/sky130B); then **hardening** (RTL→GDS); then **precheck**; on any failure, **Collect logs on failure** runs and uploads a summary plus per-job logs. |

**Job flow:**
1. **sim-rtl** — `make setup` (Caravel, cocotb, PDK) → GPIO defaults → `make verify-all-rtl`. Must pass before hardening. On failure, uploads sim logs.
2. **hardening** — `make setup` (PDK + LibreLane/OpenLane) → `get_designs.py` → `make <design>` for each macro → upload design artifact. On failure, uploads OpenLane runs.
3. **precheck** — Downloads design artifact, configures GPIO, runs `make run-precheck` with `PRECHECK_SKIP_XOR=1` (XOR check skipped in CI to avoid golden-vs-hardened GDS differences). On failure, uploads precheck_results.
4. **Collect logs on failure** — Runs only when any previous job fails; uploads a failure-summary artifact and relies on per-job “Upload logs on failure” artifacts for debugging.

To see runs and artifacts: **Actions** tab on GitHub: [shameerrao/caravel_user_project/actions](https://github.com/shameerrao/caravel_user_project/actions). If you use your own fork, use your fork’s Actions URL instead.

---

## GitHub self-hosted runner
The CI workflow uses `ubuntu-latest` by default. To run the same workflow on your own machine (e.g. for faster or private runs), add a self-hosted runner and point the workflow at it.

### 1. Requirements on the runner machine
- **OS:** Linux (recommended; x64).
- **Docker:** [Install Docker](https://docs.docker.com/engine/install/) and ensure the runner user can run `docker` (e.g. in `docker` group).
- **Python:** Python 3.8+ with `pip`.
- **Disk:** Enough space for PDK, OpenLane, and build artifacts (tens of GB recommended).
- **Network:** Outbound HTTPS to GitHub and to pull container images.

### 2. Add the runner in GitHub
1. Open this repo on GitHub → **Settings** → **Actions** → **Runners**.
2. Click **New self-hosted runner**.
3. Select **Linux** and **x64** (or your architecture).
4. GitHub will show a block of commands; run them on your machine in a dedicated directory (e.g. `~/actions-runner`).

### 3. Install and configure (on the runner machine)
Run the commands GitHub provides. They look like:

```bash
# Create a folder and enter it
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download the runner package (use the URL and token from GitHub’s instructions)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf actions-runner-linux-x64-2.311.0.tar.gz

# Configure (replace <token> with the value from GitHub; use your fork’s URL if you use a fork)
./config.sh --url https://github.com/shameerrao/caravel_user_project --token <token>

# Optional: install as a service so it starts on boot
./svc.sh install
./svc.sh start
```

Use the exact **URL** and **token** from the GitHub “Add new self-hosted runner” page; the script will prompt for labels. If you added the runner to your own fork, use your fork’s repo URL in the `--url` above.

### 4. Labels
When configuring the runner, use at least:

- `self-hosted`
- `linux`
- `x64`

To use this runner for CI, edit [`.github/workflows/user_project_ci.yml`](.github/workflows/user_project_ci.yml) and set `runs-on: [self-hosted, linux, x64]` for the jobs that should run on your machine (e.g. `hardening`, `rtl-verification`, `precheck`). Leave `ubuntu-latest` if you want those jobs to run on GitHub-hosted runners.

### 5. Verify
- In **Settings → Actions → Runners**, the new runner should appear as “Idle”.
- Push a commit or go to **Actions** → **CI** → **Run workflow** to trigger a run; if you changed the workflow to use the self-hosted runner, the jobs will run on your machine.

For more details and security notes, see [GitHub: Adding self-hosted runners](https://docs.github.com/en/actions/guides/adding-self-hosted-runners).

---

## Documentation & Resources
For detailed hardware specifications and register maps, refer to the following official documents:

* **[Caravel Datasheet](https://github.com/chipfoundry/caravel/blob/main/docs/caravel_datasheet_2.pdf)**: Detailed electrical and physical specifications of the Caravel harness.
* **[Caravel Technical Reference Manual (TRM)](https://github.com/chipfoundry/caravel/blob/main/docs/caravel_datasheet_2_register_TRM_r2.pdf)**: Complete register maps and programming guides for the management SoC.
* **[ChipFoundry Marketplace](https://platform.chipfoundry.io/marketplace)**: Access additional IP blocks, EDA tools, and shuttle services.

---

## Prerequisites
Ensure your environment meets the following requirements:

1. **Docker** [Linux](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) | [Windows](https://docs.docker.com/desktop/setup/install/windows-install/) | [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
2. **Python 3.8+** with `pip`.
3. **Git**: For repository management.

**One-time setup (Linux):** From the repo root, run the requirements install script to install system and Python dependencies:

```bash
./scripts/install_requirements.sh
```

Use a virtualenv (recommended):

```bash
./scripts/install_requirements.sh --venv
# then before each session: source venv/bin/activate
```

**Python only (any OS):** If Python and Docker are already installed:

```bash
pip install -r requirements.txt
```

---

## Environment script (EDA tools)
Before running `make` or any EDA flow locally, source the project environment so paths and tools are set correctly:

```bash
source env.sh
```

Optional: set the PDK when sourcing (default is `sky130A`):

```bash
source env.sh sky130B
```

This sets (among others) `UPRJ_ROOT`, `PDK_ROOT`, `CARAVEL_ROOT`, `OPENLANE_ROOT`, `MCW_ROOT`, `PDK`, and `PDKPATH`. Use the same shell (or source again in new terminals) when running hardening, verification, precheck, or other `make` targets.

| Variable | Default (after `make setup`) |
|----------|----------------------------|
| `UPRJ_ROOT` | Project root (directory containing `env.sh`) |
| `PDK_ROOT` | `$UPRJ_ROOT/dependencies/pdks` |
| `CARAVEL_ROOT` | `$UPRJ_ROOT/caravel` |
| `OPENLANE_ROOT` | `$UPRJ_ROOT/dependencies/openlane_src` |
| `MCW_ROOT` | `$UPRJ_ROOT/mgmt_core_wrapper` |
| `PDK` | `sky130A` (or `sky130B` if you passed it to `env.sh`) |

For local design verification (DV) without Docker, you can also set `GCC_PATH` to your RV32I toolchain before sourcing; see `verilog/dv/local-install.md`.

---

## Project Structure
A successful Caravel project requires a specific directory layout for the automated tools to function:

| Directory | Description |
| :--- | :--- |
| `openlane/` | Configuration files for hardening macros and the wrapper. |
| `verilog/rtl/` | Source Verilog code for the project. |
| `verilog/gl/` | Gate-level netlists (generated after hardening). |
| `verilog/dv/` | Design Verification (cocotb and Verilog testbenches). |
| `gds/` | Final GDSII binary files for fabrication. |
| `lef/` | Library Exchange Format files for the macros. |

---

## Starting Your Project

This section summarizes the concepts behind the **student tapeout flow** without adding new commands.  
Follow the commands in [Student tapeout flow: every command](#student-tapeout-flow-every-command); use this as a checklist of what each stage is doing.

### 1. Repository Setup
- Clone this repository on a Linux machine with Docker and Python 3.8+.
- Install Python dependencies (preferably in a virtualenv) using `./scripts/install_requirements.sh --venv`.
- Always activate your venv and `source env.sh` before running any `make` targets.

### 2. Environment Setup
- `make setup` (with `DISABLE_DEPRECATED_MAKEFILE_PROMPT=1`) installs:
  - Caravel Lite (golden SoC wrapper and reference GDS/LEF/netlists).
  - Management core wrapper (`mgmt_core_wrapper`).
  - PDKs under `dependencies/pdks`.
  - LibreLane/OpenLane and timing scripts for hardening and STA.

### 3. Development Flow (conceptual)

- **GPIO configuration**: Set power-on modes for GPIO 5–37 by editing `verilog/rtl/user_defines.v`.  
  The helper script `scripts/gpio_config.py` is the recommended way to keep this consistent.

- **Simulation (DV)**:
  - Tests live under `verilog/dv/` (RTL and cocotb).
  - `make verify-<test_name>-rtl` / `make verify-<test_name>-gl` use a DV Docker image plus your hardened Caravel to run tests.
  - Always configure GPIOs before running verification.

- **Hardening (RTL → GDS)**:
  - Each macro has an `openlane/<macro_name>/config.json` (or `config.tcl`) that defines its OpenLane run.
  - `make -C openlane list` shows available designs.
  - `make <macro_name>` runs LibreLane/OpenLane for that macro.
  - `python3 .github/scripts/get_designs.py --design $(pwd)` plus `make "$design"` in a loop hardens all macros in dependency order (see the tapeout flow section above).

- **Precheck (shuttle readiness)**:
  - `make run-precheck` runs the Efabless MPW precheck in a container using your hardened `user_project_wrapper.gds`.
  - This includes LVS/DRC, XOR, documentation/license checks, and multiple KLayout-based rule decks.
  - For quick iterations, you can set `DISABLE_LVS=1` to skip LVS while keeping the other checks.

- **Static Timing Analysis (STA)**:
  - After hardening and parasitic extraction, `make caravel-sta` runs multi-corner timing on the Caravel+user design.
  - Use this to debug slow paths and validate that the design meets timing before tapeout.

---

## GPIO Configuration
Configure the power-on default configuration for each GPIO by editing `verilog/rtl/user_defines.v`.

**Recommended (CLI-free) helper script:**
```bash
python3 scripts/gpio_config.py --set-all GPIO_MODE_USER_STD_INPUT_NOPULL
```

Examples:

```bash
# Set all GPIO 5-37 to a specific mode
python3 scripts/gpio_config.py --set-all GPIO_MODE_USER_STD_INPUT_NOPULL

# Set a range and a couple of pins
python3 scripts/gpio_config.py --set 5-10=GPIO_MODE_USER_STD_OUTPUT --set 11,12=GPIO_MODE_USER_STD_INPUT_PULLUP
```

**GPIO Pin Information:**
- GPIO[0] to GPIO[4]: Preset system pins (do not change).
- GPIO[5] to GPIO[37]: User-configurable pins.

**Available GPIO Modes:**
- Management modes: `mgmt_input_nopull`, `mgmt_input_pulldown`, `mgmt_input_pullup`, `mgmt_output`, `mgmt_bidirectional`, `mgmt_analog`
- User modes: `user_input_nopull`, `user_input_pulldown`, `user_input_pullup`, `user_output`, `user_bidirectional`, `user_output_monitored`, `user_analog`

> [!NOTE]
> GPIO configuration is required before running precheck or verification. Invalid modes will cause simulation/precheck failures.

---

## Local Precheck
Before submitting your design for fabrication, run the local precheck to ensure it complies with all shuttle requirements:

> [!IMPORTANT]
> GPIO configuration is required before running precheck.

```bash
source env.sh
python3 scripts/gpio_config.py --set-all GPIO_MODE_USER_STD_INPUT_NOPULL
export DISABLE_DEPRECATED_MAKEFILE_PROMPT=1
make run-precheck
```

You can also run specific checks or disable LVS:

```bash
# Skip LVS check
DISABLE_LVS=1 make run-precheck
```

If the **XOR** check fails (e.g. “non-conforming geometries” vs. the golden reference), you can skip it the same way CI does: `PRECHECK_SKIP_XOR=1 make run-precheck`. For submission, fix any real geometry issues or confirm with your shuttle provider.

---

## Layout Diagram

You can generate a layout diagram (similar to the Vanilla Caravel + user_project_wrapper → Caravel style) using KLayout and the provided scripts:

1. **KLayout** must be installed and on your PATH ([klayout.de](https://www.klayout.de)).
2. **Pillow**: `pip install Pillow`

From the project root you can generate a layout diagram PNG locally (requires KLayout installed on your account) or view the GDS directly.

**Option 1 — View layout in KLayout (recommended with PuTTY + XLaunch):**

1. **Start XLaunch on Windows**
   - Run **XLaunch**.
   - Choose **"Multiple windows"** (or "One large window").
   - Leave display as the default (e.g. `:0`).
   - On the "Extra settings" page, enable **"Disable access control"** so SSH‑forwarded X11 connections from PuTTY are allowed.
   - Finish and leave XLaunch running.

2. **Configure PuTTY for X11 forwarding**
   - In PuTTY, load your SSH session (if it's your first time SSH into the server on PuTTY, save it, then load).
   - Go to **Connection → SSH → X11**.
   - Check **"Enable X11 forwarding"**.
   - (Optional) Set **X display location** to `localhost:0`.
   - Go back to **Session**, save the session, and **Open** it.

3. **Launch KLayout from the Linux server**

**Update this path:** `cd` to **your** project root (the directory where you cloned the repo). Example:

```bash
cd /path/to/caravel_user_project    # ← REPLACE with your actual path (e.g. your home or course directory)
# Or from anywhere inside the repo:  cd $(git rev-parse --show-toplevel)
export PROJECT_ROOT="$PWD"
source env.sh
# If KLayout is in a custom location on your account, set LD_LIBRARY_PATH as needed
export QT_QPA_PLATFORM=xcb          # for X11 forwarding (PuTTY + XLaunch on Windows)
klayout gds/user_project_wrapper.gds &
```

If X11 forwarding is working, a KLayout window will appear on your Windows desktop. Ensure `gds/user_project_wrapper.gds` exists (run hardening first if needed).

**Option 2 — Magic layout viewer (no KLayout required):**

```bash
source env.sh
make view-layout-magic
```

Or run Magic directly: `magic gds/user_project_wrapper.gds` (with display). If the PDK is set (`PDKPATH` or `PDK_ROOT`), Magic can use the Skywater tech for correct layers.

---

## Where to update paths

These are the only places you need to set your own paths or URLs. Nothing in this repo points to instructor or server-specific locations.

| Where | What to set |
|-------|-------------|
| **Layout Diagram (KLayout)** | `cd /path/to/caravel_user_project` — use **your** project root (where you ran `git clone`). From inside the repo you can use `cd $(git rev-parse --show-toplevel)` instead. |
| **Layout Diagram (KLayout)** | If KLayout is installed in a custom location on your machine, set `LD_LIBRARY_PATH` as required by your install. |
| **Self-hosted runner** | If you add a runner to **your fork** (not this template repo), use your fork’s URL in `config.sh --url https://github.com/YOUR_USERNAME/caravel_user_project`. |
| **CI badge in README** | If you maintain your own fork and want the badge to show your fork’s CI status, edit the badge URL at the top of this README to your fork’s Actions workflow URL. |
| **Scripts** | `env.sh` and `scripts/install_requirements.sh` use the directory they live in as the project root; no path edits needed unless you move the repo. |

All other commands in this README use paths relative to the project root (e.g. `gds/`, `verilog/rtl/`) and work from wherever you cloned the repo.

---

## Checklist for Shuttle Submission
- [ ] Top-level macro is named user_project_wrapper.
- [ ] Full Chip Simulation passes for both RTL and GL.
- [ ] Hardened Macros are LVS and DRC clean.
- [ ] user_project_wrapper matches the required pin order/template.
- [ ] Design passes the local precheck (`make run-precheck`).
- [ ] Documentation (this README) is updated with project-specific details.
