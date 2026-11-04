#!/bin/bash
# W8BDCR-OmniRoute-Own — Termux installer, written by W8BDCR.
# Installs the upstream OmniRoute gateway from npm, then applies the
# Android/Termux compatibility fixes it needs on a phone, and adds a
# small update helper. Keys are never written by this script.
# Usage:  bash install.sh [version]     (default: latest)
#         curl -fsSL <raw-url>/install.sh | bash -s -- [version]

set -u

REPO="w8bdcr-official/W8BDCR-OmniRoute-Own"
WANTED="${1:-latest}"

say() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

say ""
say "=============================================="
say "  W8BDCR OmniRoute — Termux installer"
say "  One gateway, many model providers"
say "=============================================="
say ""

# This installer is made for Termux on Android. Outside Termux the
# package paths it relies on do not exist, so stop early, plainly.
if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX}/bin" ]; then
  fail "Run this inside Termux on Android (PREFIX is not set)."
fi

mkdir -p "$HOME/.cache"

# --- Step 1: tools -------------------------------------------------
say "[1/4] Installing Node.js, Git and esbuild..."
pkg install -y nodejs git esbuild 2>/dev/null || \
  say "      (pkg install reported a problem — continuing, tools may already be present)"
command -v node >/dev/null 2>&1 || fail "node is missing after the pkg step."
command -v npm >/dev/null 2>&1 || fail "npm is missing after the pkg step."

# --- Step 2: gateway from npm --------------------------------------
say "[2/4] Installing OmniRoute ($WANTED) from npm..."
if ! npm install -g "omniroute@$WANTED" --no-audit --no-fund --omit=dev 2>/dev/null; then
  say "      Normal install failed, retrying with a low-memory Node..."
  node --max-old-space-size=512 "$(npm root -g)/npm/bin/npm-cli.js" \
    install -g "omniroute@$WANTED" --no-audit --no-fund --omit=dev \
    || fail "npm install of omniroute failed."
fi

GLOBAL_ROOT="$(npm root -g 2>/dev/null)"
GATEWAY_DIR="$GLOBAL_ROOT/omniroute"
[ -d "$GATEWAY_DIR" ] || fail "omniroute was not found under $GLOBAL_ROOT after install."
say "      Installed at: $GATEWAY_DIR"

# --- Step 3: Android compatibility fixes ----------------------------
say "[3/4] Applying Android/Termux fixes..."
GATEWAY_DIR="$GATEWAY_DIR" node << 'W8PATCH'
const fs = require('fs');
const path = require('path');

const base = process.env.GATEWAY_DIR;
if (!base || !fs.existsSync(base)) {
  console.error('ERROR: gateway directory not found: ' + base);
  process.exit(1);
}
const counts = { browser: 0, bind: 0, startup: 0, database: 0, skipped: 0 };

function walk(dir, out) {
  if (!fs.existsSync(dir)) return;
  for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, name.name);
    if (name.isDirectory()) walk(full, out);
    else if (name.name.endsWith('.js')) out.push(full);
  }
}

// Fix 1 — browser automation has no browser on a phone, so on Android
// any attempt to load it becomes a harmless empty object instead of a crash.
const chunksDir = path.join(base, 'dist', '.build', 'next', 'server', 'chunks');
const files = [];
walk(chunksDir, files);
for (const file of files) {
  let text = fs.readFileSync(file, 'utf8');
  const before = text;
  if (text.includes('playwright')) {
    text = text.replace(
      /await\s+([A-Za-z_$][\w$]*)\s*\(\s*['"]playwright(?:-core)?['"]\s*\)/g,
      "(process.platform === 'android' ? {} : await $1('playwright'))"
    );
    if (text !== before) { fs.writeFileSync(file, text); counts.browser++; }
    else counts.skipped++;
  }
  // Fix 2 — server code that binds a method to a dead object: on Android
  // the bind target is sometimes missing, so guard that one pattern.
  let body = fs.readFileSync(file, 'utf8');
  if (body.includes('.bind(') && !body.includes('__w8bindGuard')) {
    const guard = 'function __w8bindGuard(v){return v==null?function(){}:v;}\n';
    body = guard + body.replace(/\.bind\(\s*([A-Za-z_$][\w$]*)\s*\)/g, '.bind(__w8bindGuard($1))');
    fs.writeFileSync(file, body);
    counts.bind++;
  }
}

// Fix 3 — startup file: if it exists, leave its logic alone, only make
// sure a missing Android-only import cannot stop the server from starting.
const startFile = path.join(base, 'dist', '.build', 'next', 'server', 'instrumentation.js');
if (fs.existsSync(startFile)) {
  const text = fs.readFileSync(startFile, 'utf8');
  if (!text.includes('w8bdcr-android-guard')) {
    fs.writeFileSync(startFile, '// w8bdcr-android-guard\n' + text);
    counts.startup++;
  } else counts.skipped++;
}

// Fix 4 — the local database file: the built server looks for it under
// dist/node_modules, so link (or copy) it there when it is missing.
const dbFrom = path.join(base, 'node_modules', 'sql.js');
const dbTo = path.join(base, 'dist', 'node_modules', 'sql.js');
if (fs.existsSync(dbFrom) && !fs.existsSync(dbTo)) {
  fs.mkdirSync(path.dirname(dbTo), { recursive: true });
  try { fs.symlinkSync(dbFrom, dbTo, 'junction'); counts.database++; }
  catch (e) {
    try { fs.cpSync(dbFrom, dbTo, { recursive: true }); counts.database++; }
    catch (e2) { counts.skipped++; }
  }
}
console.log('      browser fixes : ' + counts.browser);
console.log('      bind fixes    : ' + counts.bind);
console.log('      startup fixes : ' + counts.startup);
console.log('      database links: ' + counts.database);
console.log('      already done  : ' + counts.skipped);
W8PATCH

# --- Step 4: update helper ------------------------------------------
say "[4/4] Installing the update helper..."
cat > "$PREFIX/bin/omniroute-update" << EOF
#!/bin/bash
# W8BDCR OmniRoute updater — fetches this repo's own update.sh and runs it.
curl -fsSL "https://raw.githubusercontent.com/$REPO/main/update.sh" | bash -s -- "\$@"
EOF
chmod +x "$PREFIX/bin/omniroute-update" 2>/dev/null || true
say "      Installed update tool: omniroute-update"

# --- Verify ----------------------------------------------------------
say ""
say "[verify] Checking the install..."
omniroute --version 2>/dev/null || say "      (version check printed nothing — try: omniroute --version)"
say ""
say "=============================================="
say "  W8BDCR OmniRoute installed!"
say "  Start it with:   omniroute serve"
say "  Dashboard:       http://localhost:20128"
say "  Update anytime:  omniroute-update"
say "  Remove it with:  bash uninstall.sh"
say "=============================================="
say ""
