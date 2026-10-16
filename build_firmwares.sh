#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build_firmwares.sh [options] [all|default|vial]

Build both Andromeda keymaps by default. Keep the build cache for faster rebuilds.

Options:
  --clean             Remove the repository's build cache before building
  --skip-submodules   Use the installed submodules without updating them
  -j, --jobs N        Number of parallel compilation jobs (default: JOBS or 1)
  -n, --dry-run       Validate targets and print commands without changing files
  -h, --help          Show this help
EOF
}

clean=false
update_submodules=true
jobs=${JOBS:-1}
dry_run=false
keymap=all
target_selected=false

while (($#)); do
  case "$1" in
    --clean) clean=true ;;
    --skip-submodules) update_submodules=false ;;
    -n|--dry-run) dry_run=true ;;
    -j|--jobs)
      if [[ $# -lt 2 || ! "$2" =~ ^[1-9][0-9]*$ ]]; then
        printf 'Error: %s requires a positive integer.\n' "$1" >&2
        exit 2
      fi
      jobs=$2
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    all|default|vial)
      if [[ "$target_selected" == true ]]; then
        printf 'Error: select only one target: all, default, or vial.\n' >&2
        exit 2
      fi
      keymap=$1
      target_selected=true
      ;;
    *) printf 'Error: unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! "$jobs" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Error: jobs must be a positive integer.\n' >&2
  exit 2
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
# Use this fork even if the QMK CLI is configured for another checkout.
export QMK_HOME="$PWD"

commands=(make qmk)
if [[ "$update_submodules" == true ]]; then
  commands+=(git)
fi
for command in "${commands[@]}"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

keymaps=(default vial)
if [[ "$keymap" != all ]]; then
  keymaps=("$keymap")
fi

# Validate every selected target before updating submodules or cleaning.
for keymap in "${keymaps[@]}"; do
  if [[ ! -f keyboards/razerban/andromeda/keyboard.json ]] ||
     [[ ! -f "keyboards/razerban/andromeda/keymaps/$keymap/keymap.c" &&
        ! -f "keyboards/razerban/andromeda/keymaps/$keymap/keymap.json" ]]; then
    printf 'Error: missing keyboard metadata or keymap for razerban/andromeda:%s.\n' "$keymap" >&2
    exit 1
  fi
done

step=setup
trap 'status=$?; printf "Error: %s failed (exit %s).\n" "$step" "$status" >&2; exit "$status"' ERR

if [[ "$update_submodules" == true && "$dry_run" == false ]]; then
  step='submodule update'
  printf '\n==> Updating submodules\n'
  # The QMK submodule helper in this fork does not propagate Git failures.
  git submodule sync --recursive
  git submodule update --init --recursive
fi

if [[ "$clean" == true ]]; then
  step=clean
  if [[ "$dry_run" == true ]]; then
    printf '\nWould clean once before building: make clean\n'
  else
    make clean
  fi
fi

compile_args=(--parallel "$jobs")
if [[ "$dry_run" == true ]]; then
  compile_args+=(--dry-run)
fi

index=0
for keymap in "${keymaps[@]}"; do
  index=$((index + 1))
  step="Andromeda $keymap build"
  printf '\n[%s/%s] razerban/andromeda:%s\n' "$index" "${#keymaps[@]}" "$keymap"
  qmk compile -kb razerban/andromeda -km "$keymap" "${compile_args[@]}"
done

if [[ "$dry_run" == true ]]; then
  printf '\nValidated %s build commands. Submodules and build files were left unchanged.\n' "${#keymaps[@]}"
  exit 0
fi

printf '\nBuild complete. Firmware files:\n'
for keymap in "${keymaps[@]}"; do
  printf '  %s/razerban_andromeda_%s.uf2\n' "$PWD" "$keymap"
done
