#!/bin/bash
# W8BDCR-OmniRoute-Own — uninstaller, written by W8BDCR.
# Removes the gateway, the update helper, and — only with --purge —
# its local config. Your provider keys are never read or sent anywhere.
# Usage:  bash uninstall.sh [--yes] [--purge]

set -u

YES=0
PURGE=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --purge) PURGE=1 ;;
  esac
done

if [ "$YES" -eq 0 ]; then
  printf 'Remove W8BDCR OmniRoute? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Uninstall cancelled."; exit 0 ;;
  esac
fi

echo "Removing the gateway..."
npm uninstall -g omniroute 2>/dev/null || echo "(gateway was already gone or npm reported a problem)"

if [ -n "${PREFIX:-}" ] && [ -f "$PREFIX/bin/omniroute-update" ]; then
  rm -f "$PREFIX/bin/omniroute-update"
  echo "Removed: omniroute-update helper"
fi

if [ "$PURGE" -eq 1 ]; then
  for dir in "$HOME/.omniroute" "$HOME/.config/omniroute"; do
    if [ -d "$dir" ]; then
      rm -rf "$dir"
      echo "Purged: $dir"
    fi
  done
else
  echo "Config was left in place. Run with --purge to remove it too."
fi

echo "W8BDCR OmniRoute uninstalled."
