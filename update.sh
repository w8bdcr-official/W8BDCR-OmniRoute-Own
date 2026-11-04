#!/bin/bash
# W8BDCR-OmniRoute-Own — updater, written by W8BDCR.
# Checks the installed version against npm, reinstalls only when there
# is a newer one (or --force is given), then re-runs the installer so
# the Android fixes are applied to the fresh copy as well.
# Usage:  bash update.sh [--auto] [--force]

set -u

AUTO=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --auto) AUTO=1 ;;
    --force) FORCE=1 ;;
  esac
done

command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found." >&2; exit 1; }
command -v omniroute >/dev/null 2>&1 || { echo "ERROR: omniroute is not installed — run install.sh first." >&2; exit 1; }

CURRENT="$(omniroute --version 2>/dev/null | tr -d '[:space:]')"
LATEST="$(npm view omniroute version 2>/dev/null | tr -d '[:space:]')"
echo "Installed: ${CURRENT:-unknown}"
echo "Latest:    ${LATEST:-unknown}"

if [ "$FORCE" -eq 0 ] && [ -n "$CURRENT" ] && [ -n "$LATEST" ] && [ "$CURRENT" = "$LATEST" ]; then
  echo "Already up to date. Nothing to do."
  exit 0
fi

if [ "$AUTO" -eq 0 ]; then
  printf 'Update to %s? [y/N] ' "${LATEST:-latest}"
  read -r answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Update cancelled."; exit 0 ;;
  esac
fi

echo "Updating OmniRoute..."
npm install -g "omniroute@${LATEST:-latest}" --no-audit --no-fund --omit=dev \
  || { echo "ERROR: npm update failed." >&2; exit 1; }

# Re-apply the Android fixes by re-running our own installer in
# "already installed" mode: it reinstalls the same version and patches it.
# (When run from the repo, install.sh sits next to this file.)
HERE="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
if [ -f "$HERE/install.sh" ]; then
  bash "$HERE/install.sh" "${LATEST:-latest}"
else
  echo "Note: install.sh was not found next to update.sh, so Android fixes were not re-applied."
  echo "Run install.sh once to re-apply them."
fi
echo "OmniRoute updated."
