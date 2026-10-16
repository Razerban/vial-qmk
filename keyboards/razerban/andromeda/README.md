# Ai03 Andromeda replacement PCB by Razerban

QMK/Vial firmware for the Ai03 Andromeda replacement PCB by
[Ahmed ABDELKAFI (Razerban)](https://github.com/Razerban).

- Hardware: RP2040, 6 × 17 matrix, COL2ROW diodes.
- Indicators: Caps Lock on GP16 and Scroll Lock on GP0, active high.
- USB polling: 1 ms. Debounce: QMK's default 5 ms.
- Keymaps: `default` and `vial`, each with six initial layers.

## Build

From the repository root, after installing the QMK CLI, Make and the ARM toolchain:

```sh
./build_firmwares.sh                         # Update submodules and build both
./build_firmwares.sh --skip-submodules -j 4   # Rebuild using installed submodules
./build_firmwares.sh --skip-submodules vial  # Build only Vial
./build_firmwares.sh --clean -j 4            # Start with a fresh build cache
./build_firmwares.sh --dry-run --clean       # Validate and preview without changes
JOBS=4 ./build_firmwares.sh --skip-submodules
./build_firmwares.sh --help
```

The script also works when invoked by its path from another directory. It stops
on failure and retains the build cache for incremental builds. `--clean` removes
the entire repository's `.build` cache before compiling. Submodule updates run
by default; use `--skip-submodules` when working offline or retaining local
submodule changes. Updates use Git directly and stop on Git errors. The script
pins `QMK_HOME` to this checkout and checks all selected targets before updating
or cleaning. `JOBS` supplies the default job count; `-j` overrides it.

`--dry-run` prints the QMK build commands without updating submodules, cleaning
or compiling. Builds retain Git version information.

Successful builds write `razerban_andromeda_default.uf2` and/or
`razerban_andromeda_vial.uf2` to the repository root. The script does not flash
the keyboard.

Direct Make targets are also available:

```sh
make razerban/andromeda:default
make razerban/andromeda:vial
```

## Configuration

`keyboard.json` defines the processor, bootloader, matrix wiring, indicators,
USB identity, enabled features and generated `LAYOUT` macro. Key order and
matrix coordinates must remain aligned with the keymaps. The Enter argument
maps to `[3, 12]`, preserving the original C layout macro.

Vial-specific settings remain in `keymaps/vial/`: six dynamic layers, the
existing keyboard UID and the unlock combo at matrix positions `[0, 0]`
(Escape) and `[3, 12]`. `vial.json` describes the selectable physical layouts,
including alternate switch positions that are absent from the initial keymap.

Known discrepancy retained by decision on 2026-10-16: the firmware maps Enter
to `[3, 12]`, while `vial.json` places both ANSI and ISO Enter at `[3, 13]`
and the extra ISO key at `[3, 12]`. Supplied configurations from the other QMK
project have the same mismatch. The conversion preserves the original firmware
behavior; physical wiring has not been confirmed. Leave both definitions as-is
unless that decision is explicitly reopened.

## Validation

```sh
qmk lint -kb razerban/andromeda -km default --strict
bash -n build_firmwares.sh
```

This fork retains upstream QMK lint rules that reject keymaps named `vial`.
Running lint without `-km default` therefore fails on that naming rule; validate
the Vial target by building it as well.

Build setup details are in the repository's
[getting started guide](../../../docs/newbs_getting_started.md).
