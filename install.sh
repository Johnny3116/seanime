#!/usr/bin/env bash
# Seanime installer — Linux / macOS
# Run from the project root: bash install.sh
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  !${NC} $*"; }
fail() { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }

REQUIRED_GO_MAJOR=1
REQUIRED_GO_MINOR=23
REQUIRED_NODE_MAJOR=18

# ─── Prerequisite checks ──────────────────────────────────────────────────────

log "Checking prerequisites..."

# Go
if ! command -v go &>/dev/null; then
    fail "Go is not installed. Install Go $REQUIRED_GO_MAJOR.$REQUIRED_GO_MINOR+ from https://go.dev/doc/install"
fi
GO_VERSION=$(go version | grep -oE '[0-9]+\.[0-9]+' | head -1)
GO_MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
GO_MINOR=$(echo "$GO_VERSION" | cut -d. -f2)
if [[ "$GO_MAJOR" -lt "$REQUIRED_GO_MAJOR" ]] || \
   [[ "$GO_MAJOR" -eq "$REQUIRED_GO_MAJOR" && "$GO_MINOR" -lt "$REQUIRED_GO_MINOR" ]]; then
    fail "Go $REQUIRED_GO_MAJOR.$REQUIRED_GO_MINOR+ required (found $GO_VERSION). https://go.dev/doc/install"
fi
ok "Go $GO_VERSION"

# Node.js
if ! command -v node &>/dev/null; then
    fail "Node.js is not installed. Install Node.js $REQUIRED_NODE_MAJOR+ from https://nodejs.org"
fi
NODE_MAJOR=$(node --version | grep -oE '[0-9]+' | head -1)
if [[ "$NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]]; then
    fail "Node.js $REQUIRED_NODE_MAJOR+ required (found $(node --version)). https://nodejs.org"
fi
ok "Node.js $(node --version)"

# npm
if ! command -v npm &>/dev/null; then
    fail "npm is not installed. It is bundled with Node.js — https://nodejs.org"
fi
ok "npm $(npm --version)"

echo ""

# ─── Step 1: Frontend dependencies ───────────────────────────────────────────

log "Step 1/5 — Installing frontend dependencies..."
cd seanime-web
npm install
ok "Dependencies installed"
cd ..

# ─── Step 2: Build frontend ───────────────────────────────────────────────────

log "Step 2/5 — Building frontend (this may take a minute)..."
cd seanime-web
npm run build
ok "Frontend built → seanime-web/out"
cd ..

# ─── Step 3: Copy frontend output to web/ ────────────────────────────────────

log "Step 3/5 — Copying frontend output to web/..."
rm -rf web
cp -r seanime-web/out web
ok "Output copied → web/"

# ─── Step 4: Download Go modules ─────────────────────────────────────────────

log "Step 4/5 — Downloading Go modules..."
go mod download
ok "Go modules ready"

# ─── Step 5: Build server binary ─────────────────────────────────────────────

log "Step 5/5 — Building Seanime server..."
go build -o seanime -trimpath -ldflags="-s -w"
ok "Server built → ./seanime"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}Seanime installed successfully!${NC}"
echo ""
echo "Run it with:"
echo "  ./seanime --datadir=\"/path/to/your/data\""
echo ""
echo "On first run, edit config.toml in your data directory:"
echo "  port = 43000"
echo "  host = \"0.0.0.0\""
echo ""
