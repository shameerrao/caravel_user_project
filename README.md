# Caravel User Project

## Overview

This repository contains a sample user project for the [Caravel](https://github.com/chipfoundry/caravel.git) chip user space. It includes a simple counter demonstrating how to use Caravel's utilities such as IO pads, logic analyzer probes, and the Wishbone port. The repository also follows the recommended structure for open-mpw shuttle projects.

## Prerequisites

- Docker: [Linux](https://docs.docker.com/desktop/setup/install/linux/ubuntu/) | [Windows](https://docs.docker.com/desktop/setup/install/windows-install/) | [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
- Python 3.8+ with PIP

## Starting Your Project

1. Create a new repository based on the [caravel_user_project](https://github.com/chipfoundry/caravel_user_project/) template.

   - Follow [this link](https://github.com/chipfoundry/caravel_user_project/generate) to create your repository.
   - Clone the repository using:

     ```bash
     git clone <your github repo URL>
     ```
3. Install ChipFoundry CLI tool:

   ```bash
   pip install cf-cli
   ```

3. Set up your local environment:

   ```bash
   cd <project_name>
   cf setup
   ```

   This command installs:

   - caravel_lite
   - Management core for simulation
   - OpenLane for design hardening
   - PDK
   - Timing scripts

3. Start hardening your design:

   - For hardening, provide an RTL Verilog model of your design to OpenLane.
   - Create a subdirectory for each macro in your project under the `openlane/` directory with OpenLane configuration files.

     ```bash
     cf harden --list # To list all the config files found in your project
     cf harden <macro_name>
     ```

   Refer to [the example configuration](./openlane/user_proj_example/config.json) for an example config file.

4. Integrate modules into the user_project_wrapper:

   - Update environment variables `VERILOG_FILES_BLACKBOX`, `EXTRA_LEFS`, and `EXTRA_GDS_FILES` in `openlane/user_project_wrapper/config.tcl` to point to your module.
   - Instantiate your module(s) in `verilog/rtl/user_project_wrapper.v`.
   - Harden the user_project_wrapper with your module(s):

     ```bash
     cf harden user_project_wrapper
     ```

5. Run cocotb simulation on your design:

   - Update `rtl/gl` files in `verilog/includes/includes.<rtl/gl>.caravel_user_project`.
   - Run `gen_gpio_defaults.py` script to generate `caravel_core.v`.
   - Run RTL tests:

     ```bash
     cf verify <test_name>
     ```

   - For GL simulation:

     ```bash
     cf verify <test_name> --sim GL
     ```

   - To add cocotb tests, refer to [Adding cocotb test](https://caravel-sim-infrastructure.readthedocs.io/en/latest/usage.html#adding-a-test).

6. Run opensta on your design:

   - Extract parasitics for `user_project_wrapper` and its macros:

     ```bash
     make extract-parasitics
     ```

   - Create a spef mapping file:

     ```bash
     make create-spef-mapping
     ```

   - Run opensta:

     ```bash
     make caravel-sta
     ```

 > [!NOTE]
 > To update timing scripts, run `make setup-timing-scripts`.

7. Run the precheck locally:

   ```bash
   cf precheck
   ```


### GPIO Configuration

Specify the power-on default configuration for each GPIO in Caravel in `verilog/rtl/user_defines.v`. GPIO[5] to GPIO[37] require configuration, while GPIO[0] to GPIO[4] are preset and cannot be changed.

### Layout Integration

The Caravel layout includes an empty golden wrapper in the user space. Provide a valid `user_project_wrapper` GDS file. Your hardened `user_project_wrapper` will be integrated into the Caravel layout during tapeout.

![Layout](./_static/layout.png)

Ensure your hardened `user_project_wrapper` meets the requirements in [User Project Wrapper Requirements](#user-project-wrapper-requirements).


## Checklist for Shuttle Submission

- ✔️ Top level macro is named `user_project_wrapper`.
- ✔️ Full Chip Simulation passes for RTL and GL.
- ✔️ Hardened Macros are LVS and DRC clean.
- ✔️ `user_project_wrapper` matches the [pin order](https://github.com/chipfoundry/caravel/blob/master/openlane/user_project_wrapper_empty/pin_order.cfg).
- ✔️ Design passes the [precheck](https://github.com/chipfoundry/mpw_precheck).
