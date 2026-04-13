# Seanime installer — Windows (PowerShell)
# Run from the project root: .\install.ps1
#
# Optional flags:
#   -NoSystemTray    Build without Windows system tray (used by the desktop app)
#
# Example:
#   .\install.ps1
#   .\install.ps1 -NoSystemTray

param(
    [switch]$NoSystemTray
)

$ErrorActionPreference = "Stop"

$REQUIRED_GO_MAJOR   = 1
$REQUIRED_GO_MINOR   = 23
$REQUIRED_NODE_MAJOR = 18

function Log  { param($msg) Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok   { param($msg) Write-Host "  + $msg" -ForegroundColor Green }
function Fail { param($msg) Write-Host "  X ERROR: $msg" -ForegroundColor Red; exit 1 }

# ─── Prerequisite checks ──────────────────────────────────────────────────────

Log "Checking prerequisites..."

# Go
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Fail "Go is not installed. Install Go $REQUIRED_GO_MAJOR.$REQUIRED_GO_MINOR+ from https://go.dev/doc/install"
}
$goOut = go version
if ($goOut -match 'go(\d+)\.(\d+)') {
    $goMajor = [int]$Matches[1]; $goMinor = [int]$Matches[2]
    if ($goMajor -lt $REQUIRED_GO_MAJOR -or
       ($goMajor -eq $REQUIRED_GO_MAJOR -and $goMinor -lt $REQUIRED_GO_MINOR)) {
        Fail "Go $REQUIRED_GO_MAJOR.$REQUIRED_GO_MINOR+ required. https://go.dev/doc/install"
    }
}
Ok "Go — $goOut"

# Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Fail "Node.js is not installed. Install Node.js $REQUIRED_NODE_MAJOR+ from https://nodejs.org"
}
$nodeVer = node --version
if ($nodeVer -match 'v(\d+)' -and [int]$Matches[1] -lt $REQUIRED_NODE_MAJOR) {
    Fail "Node.js $REQUIRED_NODE_MAJOR+ required (found $nodeVer). https://nodejs.org"
}
Ok "Node.js $nodeVer"

# npm
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Fail "npm is not installed. It is bundled with Node.js — https://nodejs.org"
}
Ok "npm $(npm --version)"

Write-Host ""

# ─── Step 1: Frontend dependencies ───────────────────────────────────────────

Log "Step 1/5 — Installing frontend dependencies..."
Push-Location seanime-web
npm install
if ($LASTEXITCODE -ne 0) { Fail "npm install failed" }
Ok "Dependencies installed"
Pop-Location

# ─── Step 2: Build frontend ───────────────────────────────────────────────────

Log "Step 2/5 — Building frontend (this may take a minute)..."
Push-Location seanime-web
npm run build
if ($LASTEXITCODE -ne 0) { Fail "Frontend build failed" }
Ok "Frontend built -> seanime-web\out"
Pop-Location

# ─── Step 3: Copy frontend output to web\ ────────────────────────────────────

Log "Step 3/5 — Copying frontend output to web\..."
if (Test-Path web) { Remove-Item -Recurse -Force web }
Copy-Item -Recurse seanime-web\out web
Ok "Output copied -> web\"

# ─── Step 4: Download Go modules ─────────────────────────────────────────────

Log "Step 4/5 — Downloading Go modules..."
go mod download
if ($LASTEXITCODE -ne 0) { Fail "go mod download failed" }
Ok "Go modules ready"

# ─── Step 5: Build server binary ─────────────────────────────────────────────

Log "Step 5/5 — Building Seanime server..."
if ($NoSystemTray) {
    # Used by the Electron desktop app — no system tray, no CGO requirement
    go build -o seanime.exe -trimpath -ldflags="-s -w" -tags=nosystray
} else {
    # Standard Windows build with system tray (requires a C compiler, e.g. MinGW)
    $env:CGO_ENABLED = "1"
    go build -o seanime.exe -trimpath -ldflags="-s -w -H=windowsgui -extldflags '-static'"
}
if ($LASTEXITCODE -ne 0) { Fail "Server build failed" }
Ok "Server built -> seanime.exe"

# ─── Done ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Seanime installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Run it with:"
Write-Host "  .\seanime.exe --datadir=`"C:\path\to\your\data`""
Write-Host ""
Write-Host "On first run, edit config.toml in your data directory:"
Write-Host "  port = 43000"
Write-Host "  host = `"0.0.0.0`""
Write-Host ""
