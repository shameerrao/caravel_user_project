#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path


GPIO_MIN = 5
GPIO_MAX = 37


MODE_ALIASES = {
    "user_std_input_nopull": "GPIO_MODE_USER_STD_INPUT_NOPULL",
    "user_std_input_pulldown": "GPIO_MODE_USER_STD_INPUT_PULLDOWN",
    "user_std_input_pullup": "GPIO_MODE_USER_STD_INPUT_PULLUP",
    "user_std_output": "GPIO_MODE_USER_STD_OUTPUT",
    "user_std_bidirectional": "GPIO_MODE_USER_STD_BIDIRECTIONAL",
    "user_std_out_monitored": "GPIO_MODE_USER_STD_OUT_MONITORED",
    "user_std_analog": "GPIO_MODE_USER_STD_ANALOG",
    "mgmt_std_input_nopull": "GPIO_MODE_MGMT_STD_INPUT_NOPULL",
    "mgmt_std_input_pulldown": "GPIO_MODE_MGMT_STD_INPUT_PULLDOWN",
    "mgmt_std_input_pullup": "GPIO_MODE_MGMT_STD_INPUT_PULLUP",
    "mgmt_std_output": "GPIO_MODE_MGMT_STD_OUTPUT",
    "mgmt_std_bidirectional": "GPIO_MODE_MGMT_STD_BIDIRECTIONAL",
    "mgmt_std_analog": "GPIO_MODE_MGMT_STD_ANALOG",
}


def _normalize_mode(mode: str) -> str:
    m = mode.strip()
    k = re.sub(r"[^a-z0-9]+", "_", m.lower()).strip("_")
    if k in MODE_ALIASES:
        return f"`{MODE_ALIASES[k]}"
    if re.fullmatch(r"GPIO_MODE_[A-Z0-9_]+", m):
        return f"`{m}"
    if re.fullmatch(r"`GPIO_MODE_[A-Z0-9_]+", m):
        return m
    if re.fullmatch(r"13'h[0-9a-fA-F]{1,4}", m):
        return m
    raise ValueError(
        "Unrecognized mode. Use a macro like GPIO_MODE_USER_STD_INPUT_NOPULL, "
        "an alias like user_std_input_nopull, or a literal like 13'h0402."
    )


def _parse_gpio_list(s: str) -> list[int]:
    out: list[int] = []
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            a_i = int(a)
            b_i = int(b)
            lo, hi = (a_i, b_i) if a_i <= b_i else (b_i, a_i)
            out.extend(range(lo, hi + 1))
        else:
            out.append(int(part))
    return out


def _update_user_defines(path: Path, updates: dict[int, str]) -> None:
    text = path.read_text()
    for gpio, mode in updates.items():
        if gpio < GPIO_MIN or gpio > GPIO_MAX:
            raise ValueError(f"GPIO must be in [{GPIO_MIN}, {GPIO_MAX}] (got {gpio}).")
        pattern = re.compile(rf"(`define\s+USER_CONFIG_GPIO_{gpio}_INIT\s+).*$", re.M)
        if not pattern.search(text):
            raise RuntimeError(f"Could not find USER_CONFIG_GPIO_{gpio}_INIT in {path}.")
        text = pattern.sub(rf"\1{mode}", text, count=1)
    path.write_text(text)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description="Configure GPIO power-on modes by editing verilog/rtl/user_defines.v (no chipfoundry-cli)."
    )
    ap.add_argument(
        "--file",
        default="verilog/rtl/user_defines.v",
        help="Path to user_defines.v (default: verilog/rtl/user_defines.v)",
    )
    ap.add_argument(
        "--set-all",
        metavar="MODE",
        help="Set GPIO 5-37 to MODE (e.g. GPIO_MODE_USER_STD_INPUT_NOPULL or 13'h0402).",
    )
    ap.add_argument(
        "--set",
        action="append",
        default=[],
        metavar="GPIO_SPEC=MODE",
        help="Set specific GPIO(s). GPIO_SPEC can be '5', '5-10', or '5,7,9-12'. Repeatable.",
    )

    args = ap.parse_args(argv)

    updates: dict[int, str] = {}
    if args.set_all:
        mode = _normalize_mode(args.set_all)
        for g in range(GPIO_MIN, GPIO_MAX + 1):
            updates[g] = mode

    for item in args.set:
        if "=" not in item:
            raise ValueError("--set expects GPIO_SPEC=MODE (e.g. 5-10=GPIO_MODE_USER_STD_INPUT_NOPULL).")
        gpio_spec, mode_raw = item.split("=", 1)
        mode = _normalize_mode(mode_raw)
        for g in _parse_gpio_list(gpio_spec):
            updates[g] = mode

    if not updates:
        ap.error("No updates requested. Use --set-all MODE and/or --set GPIO_SPEC=MODE.")

    path = Path(args.file)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    _update_user_defines(path, updates)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as e:
        print(f"gpio_config.py: error: {e}", file=sys.stderr)
        raise SystemExit(2)
