<div align="center">

<img src="https://umsousercontent.com/lib_lnlnuhLgkYnZdkSC/hj0vk05j0kemus1i.png" alt="ChipFoundry Logo" height="140" />

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Inter&size=44&duration=3000&pause=600&color=4C6EF5&center=true&vCenter=true&width=1100&lines=Caravel+User+Project+Template;OpenLane+%2B+ChipFoundry+Flow;Verification+and+Shuttle-Ready)](https://git.io/typing-svg)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![ChipFoundry Marketplace](https://img.shields.io/badge/ChipFoundry-Marketplace-6E40C9.svg)](https://platform.chipfoundry.io/marketplace)
[![CI](https://github.com/shameerrao/caravel_user_project/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/shameerrao/caravel_user_project/actions/workflows/user_project_ci.yml)

</div>

## Table of Contents
- [Overview](#overview)
- [This Repository](#this-repository)
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
- [Checklist for Shuttle Submission](#checklist-for-shuttle-submission)

## Overview
This repository contains a user project designed for integration into the **Caravel chip user space**. Use it as a template for integrating custom RTL with Caravel's system-on-chip (SoC) utilities, including:

* **IO Pads:** Configurable general-purpose input/output.
* **Logic Analyzer Probes:** 128 signals for non-intrusive hardware debugging.
* **Wishbone Port:** A 32-bit standard bus interface for communication between the RISC-V management core and your custom hardware.

---

## This Repository
This project is based on [chipfoundry/caravel_user_project](https://github.com/chipfoundry/caravel_user_project) and uses the **SkyWater 130 nm** open-source PDK with the Caravel harness. The RTL-to-GDS flow is driven by **OpenLane** (via ChipFoundry CLI) and runs in CI and locally with industry-standard tools: Docker, Make, Python 3, and optional self-hosted runners.

**Clone and push to your fork:**
```bash
git clone https://github.com/shameerrao/caravel_user_project.git
cd caravel_user_project
pip install chipfoundry-cli
source env.sh
cf init
cf setup
```

---

## GitHub Actions (RTL-to-GDS Pipeline)
A single workflow runs the full SkyWater 130 flow: [**CI**](.github/workflows/user_project_ci.yml) (`.github/workflows/user_project_ci.yml`).

| Runner | Trigger | What it does |
|--------|---------|--------------|
| `ubuntu-latest` (default) or [self-hosted](#github-self-hosted-runner) | Every push/PR, or **Run workflow** in Actions | **rtl-verification** first (`cf verify --all`); then **hardening** (RTL→GDS for sky130A/sky130B); then **precheck** (downloads hardening artifacts, runs `cf precheck`). |

**Job flow (linked):**
1. **rtl-verification** — Runs first; `cf setup` (Caravel, cocotb, PDK) → GPIO config → `cf verify --all`. Must pass before hardening runs.
2. **hardening** — Runs after rtl-verification; `cf setup` (PDK + OpenLane) → `get_designs.py` → `cf harden` for each macro → upload artifact (`gds/`, `signoff/`, `verilog/gl/`, `lef/`, `.cf/project.json`).
3. **precheck** — Depends on **hardening**; downloads the design artifact, configures GPIO, runs `cf precheck`.

To see runs and artifacts: [Actions tab](https://github.com/shameerrao/caravel_user_project/actions).

---

## GitHub self-hosted runner
The CI workflow uses `ubuntu-latest` by default. To run the same workflow on your own machine (e.g. for faster or private runs), add a self-hosted runner and point the workflow at it.

### 1. Requirements on the runner machine
- **OS:** Linux (recommended; x64).
- **Docker:** [Install Docker](https://docs.docker.com/engine/install/) and ensure the runner user can run `docker` (e.g. in `docker` group).
- **Python:** Python 3.8+ with `pip` (for ChipFoundry CLI).
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

# Configure (replace <token> and <repo> with the values from GitHub)
./config.sh --url https://github.com/OWNER/caravel_user_project --token <token>

# Optional: install as a service so it starts on boot
./svc.sh install
./svc.sh start
```

Use the exact **URL** and **token** from the GitHub “Add new self-hosted runner” page; the script will prompt for labels.

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

---

## Environment script (EDA tools)
Before running `cf`, `make`, or any EDA flow locally, source the project environment so paths and tools are set correctly:

```bash
source env.sh
```

Optional: set the PDK when sourcing (default is `sky130A`):

```bash
source env.sh sky130B
```

This sets (among others) `UPRJ_ROOT`, `PDK_ROOT`, `CARAVEL_ROOT`, `OPENLANE_ROOT`, `MCW_ROOT`, `PDK`, and `PDKPATH`. Use the same shell (or source again in new terminals) when running `cf setup`, `cf harden`, `cf verify`, `cf precheck`, or `make` targets.

| Variable | Default (after `cf setup`) |
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

### 1. Repository Setup
Clone this repository and install the ChipFoundry CLI:

```bash
git clone https://github.com/shameerrao/caravel_user_project.git
cd caravel_user_project
pip install chipfoundry-cli
source env.sh
```

### 2. Project Initialization

> [!IMPORTANT]
> Run this first! Initialize your project configuration:

```bash
source env.sh
cf init
```

This creates `.cf/project.json` with project metadata. **This must be run before any other commands** (`cf setup`, `cf gpio-config`, `cf harden`, `cf precheck`, `cf verify`).

### 3. Environment Setup
Set EDA paths and install dependencies (PDKs, OpenLane, Caravel lite):

```bash
source env.sh
cf setup
```

The `cf setup` command installs:

- Caravel Lite: The Caravel SoC template.
- Management Core: RISC-V management area required for simulation.
- OpenLane: The RTL-to-GDS hardening flow.
- PDK: Skywater 130nm process design kit.
- Timing Scripts: For Static Timing Analysis (STA).

---

## Development Flow

### Hardening the Design
Hardening is the process of synthesizing your RTL and performing Place & Route (P&R) to create a GDSII layout.

#### Macro Hardening
Create a subdirectory for each custom macro under `openlane/` containing your `config.tcl`.

```bash
cf harden --list         # List detected configurations
cf harden <macro_name>   # Harden a specific macro
```

#### Integration
Instantiate your module(s) in `verilog/rtl/user_project_wrapper.v`.

Update `openlane/user_project_wrapper/config.json` environment variables (`VERILOG_FILES_BLACKBOX`, `EXTRA_LEFS`, `EXTRA_GDS_FILES`) to point to your new macros.

#### Wrapper Hardening
Finalize the top-level user project:

```bash
cf harden user_project_wrapper
```

#### Full RTL-to-GDS locally (stock flow)
From the repo root, after `cf init` and `cf setup`:

```bash
source env.sh
python3 .github/scripts/get_designs.py --design $(pwd)
for design in $(cat harden_sequence.txt); do [ -z "$design" ] && continue; cf harden $design || exit 1; done
```

This hardens `user_proj_example` then `user_project_wrapper`, producing GDS under `gds/` and signoff under `signoff/`.

### Verification

#### 1. Simulation
We use cocotb for functional verification. Ensure your file lists are updated in `verilog/includes/`.

**Configure GPIO settings first (required before verification):**

```bash
cf gpio-config
```

This interactive command will:
- Configure all GPIO pins interactively
- Automatically update `verilog/rtl/user_defines.v`
- Automatically run `gen_gpio_defaults.py` to generate GPIO defaults for simulation

GPIO configuration is required before running any verification tests.

Run RTL Simulation:

```bash
cf verify <test_name>
```

Run Gate-Level (GL) Simulation:

```bash
cf verify <test_name> --sim gl
```

Run all tests:

```bash
cf verify --all
```

#### 2. Static Timing Analysis (STA)
Verify that your design meets timing constraints using OpenSTA:

```bash
make extract-parasitics
make create-spef-mapping
make caravel-sta
```

> [!NOTE]
> Run `make setup-timing-scripts` if you need to update the STA environment.

---

## GPIO Configuration
Configure the power-on default configuration for each GPIO using the interactive CLI tool.

**Use the GPIO configuration command:**
```bash
cf gpio-config
```

This command will:
- Present an interactive form for configuring GPIO pins 5-37 (GPIO 0-4 are fixed system pins)
- Show available GPIO modes with descriptions
- Allow selection by number, partial key, or full mode name
- Save configuration to `.cf/project.json` (as hex values)
- Automatically update `verilog/rtl/user_defines.v` with the new configuration
- Automatically run `gen_gpio_defaults.py` to generate GPIO defaults for simulation (if Caravel is installed)

**GPIO Pin Information:**
- GPIO[0] to GPIO[4]: Preset system pins (do not change).
- GPIO[5] to GPIO[37]: User-configurable pins.

**Available GPIO Modes:**
- Management modes: `mgmt_input_nopull`, `mgmt_input_pulldown`, `mgmt_input_pullup`, `mgmt_output`, `mgmt_bidirectional`, `mgmt_analog`
- User modes: `user_input_nopull`, `user_input_pulldown`, `user_input_pullup`, `user_output`, `user_bidirectional`, `user_output_monitored`, `user_analog`

> [!NOTE]
> GPIO configuration is required before running `cf precheck` or `cf verify`. Invalid modes cannot be saved - all GPIOs must have valid configurations.

---

## Local Precheck
Before submitting your design for fabrication, run the local precheck to ensure it complies with all shuttle requirements:

> [!IMPORTANT]
> GPIO configuration is required before running precheck. Make sure you've run `cf gpio-config` first.

```bash
source env.sh
cf precheck
```

You can also run specific checks or disable LVS:

```bash
cf precheck --disable-lvs                    # Skip LVS check
cf precheck --checks license --checks makefile  # Run specific checks only
```
---

## Checklist for Shuttle Submission
- [ ] Top-level macro is named user_project_wrapper.
- [ ] Full Chip Simulation passes for both RTL and GL.
- [ ] Hardened Macros are LVS and DRC clean.
- [ ] user_project_wrapper matches the required pin order/template.
- [ ] Design passes the local cf precheck.
- [ ] Documentation (this README) is updated with project-specific details.
