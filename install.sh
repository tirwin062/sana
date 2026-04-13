# ══════════════════════════════════════════════════════════════
# Sana Installer — Windows (PowerShell)
# ══════════════════════════════════════════════════════════════
# Usage (paste into PowerShell):
#   iwr -useb https://withnreach.com/Sana/install.ps1 | iex
#
# What this does:
#   1. Detects Windows version and architecture
#   2. Installs Node.js if not present (via winget or direct download)
#   3. Creates the Sana app in %USERPROFILE%\sana
#   4. Installs dependencies
#   5. Starts Sana in the background
#   6. Opens your browser to complete setup
# ══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

# ── Config ────────────────────────────────────────────────────
$SANA_VERSION  = "1.0.0"
$SANA_DIR      = "$env:USERPROFILE\sana"
$SANA_PORT     = 7343
$NODE_VERSION  = "20.11.0"
$NODE_MSI_URL  = "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-x64.msi"

# ── Colors ────────────────────────────────────────────────────
function Log($msg)     { Write-Host "[Sana] $msg" -ForegroundColor Magenta }
function Success($msg) { Write-Host "[Sana] ✓ $msg" -ForegroundColor Green }
function Warn($msg)    { Write-Host "[Sana] ⚠ $msg" -ForegroundColor Yellow }
function Err($msg)     { Write-Host "[Sana] ✗ $msg" -ForegroundColor Red; exit 1 }
function Step($msg)    { Write-Host "`n── $msg" -ForegroundColor Cyan }

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "   ███████╗ █████╗ ███╗   ██╗ █████╗ " -ForegroundColor Magenta
Write-Host "   ██╔════╝██╔══██╗████╗  ██║██╔══██╗" -ForegroundColor Magenta
Write-Host "   ███████╗███████║██╔██╗ ██║███████║" -ForegroundColor Magenta
Write-Host "   ╚════██║██╔══██║██║╚██╗██║██╔══██║" -ForegroundColor Magenta
Write-Host "   ███████║██║  ██║██║ ╚████║██║  ██║" -ForegroundColor Magenta
Write-Host "   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "   Educational Intelligence — v$SANA_VERSION" -ForegroundColor Cyan
Write-Host ""

# ── Detect environment ────────────────────────────────────────
Step "Detecting environment"

$OS_VERSION = [System.Environment]::OSVersion.Version
$ARCH       = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

Success "Detected: Windows $($OS_VERSION.Major).$($OS_VERSION.Minor) ($ARCH)"

# ── Check/Install Node.js ─────────────────────────────────────
Step "Checking Node.js"

function Install-Node {
  Log "Installing Node.js $NODE_VERSION..."

  # Try winget first (Windows 10+)
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    try {
      winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
      $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                  [System.Environment]::GetEnvironmentVariable("PATH", "User")
      Success "Node.js installed via winget"
      return
    } catch {
      Warn "winget install failed — trying direct download"
    }
  }

  # Direct MSI download fallback
  $msiPath = "$env:TEMP\node-installer.msi"
  Log "Downloading Node.js installer..."
  Invoke-WebRequest -Uri $NODE_MSI_URL -OutFile $msiPath -UseBasicParsing

  Log "Running Node.js installer (this may take a moment)..."
  Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msiPath`" /quiet /norestart"
  Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

  # Refresh PATH
  $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
              [System.Environment]::GetEnvironmentVariable("PATH", "User")

  Success "Node.js installed"
}

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
  $nodeVer = (node --version) -replace "v", "" -split "\." | Select-Object -First 1
  if ([int]$nodeVer -ge 18) {
    Success "Node.js $(node --version) found"
  } else {
    Warn "Node.js $(node --version) is too old — upgrading"
    Install-Node
  }
} else {
  Install-Node
}

# Verify
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Err "Node.js not found after install. Install manually from nodejs.org and re-run."
}

# ── Create Sana directory ─────────────────────────────────────
Step "Creating Sana directory"

if (Test-Path $SANA_DIR) {
  Warn "Sana directory already exists at $SANA_DIR"
  $response = Read-Host "  Update existing installation? [Y/n]"
  if ($response -eq "n" -or $response -eq "N") {
    Log "Installation cancelled"
    exit 0
  }
}

New-Item -ItemType Directory -Force -Path "$SANA_DIR\src"  | Out-Null
New-Item -ItemType Directory -Force -Path "$SANA_DIR\data" | Out-Null
New-Item -ItemType Directory -Force -Path "$SANA_DIR\logs" | Out-Null

Success "Directory created: $SANA_DIR"

# ── Download/copy Sana bundle ─────────────────────────────────
Step "Downloading Sana"

$bundleDest = "$SANA_DIR\src\sana-bundle-v11.js"

# Check local sources first
$localSources = @(
  "$(Get-Location)\sana-bundle-v11.js",
  "$env:USERPROFILE\Downloads\sana-bundle-v11.js",
  "$env:USERPROFILE\Desktop\sana-bundle-v11.js"
)

$bundleCopied = $false
foreach ($src in $localSources) {
  if (Test-Path $src) {
    Copy-Item $src $bundleDest -Force
    Success "Bundle copied from $src"
    $bundleCopied = $true
    break
  }
}

if (-not $bundleCopied) {
  Log "Downloading bundle from CDN..."
  try {
    Invoke-WebRequest `
      -Uri "https://withnreach.com/Sana/sana-bundle-v11.js" `
      -OutFile $bundleDest `
      -UseBasicParsing
    Success "Bundle downloaded"
  } catch {
    Err "Failed to download bundle: $_`nMake sure sana-bundle-v11.js is in the same folder and re-run."
  }
}

$bundleSize = (Get-Item $bundleDest).Length
if ($bundleSize -lt 50000) {
  Err "Bundle too small ($bundleSize bytes) — download may have failed"
}
Success "Bundle verified ($([math]::Round($bundleSize/1024))KB)"

# ── Write app files ───────────────────────────────────────────
Step "Writing app files"

# package.json
@'
{
  "name": "sana-desktop",
  "version": "1.0.0",
  "description": "Sana Educational Intelligence",
  "main": "src/main.js",
  "scripts": {
    "start": "electron src/main.js",
    "serve": "node src/serve.js"
  },
  "dependencies": {
    "ws": "^8.16.0"
  },
  "devDependencies": {
    "electron": "^29.0.0"
  }
}
'@ | Out-File "$SANA_DIR\package.json" -Encoding utf8

# serve.js
@'
const http  = require("http");
const fs    = require("fs");
const path  = require("path");
const { exec } = require("child_process");

const PORT     = process.env.SANA_PORT || 7343;
const SANA_DIR = path.join(__dirname, "..");

const MIME = { ".js": "application/javascript", ".html": "text/html", ".css": "text/css" };

const server = http.createServer((req, res) => {
  let filePath = path.join(SANA_DIR, "src", req.url === "/" ? "index.html" : req.url);
  const ext    = path.extname(filePath);
  if (!fs.existsSync(filePath)) { res.writeHead(404); res.end("Not found"); return; }
  res.writeHead(200, { "Content-Type": MIME[ext] || "text/plain", "Cache-Control": "no-cache", "Access-Control-Allow-Origin": "*" });
  fs.createReadStream(filePath).pipe(res);
});

server.listen(PORT, "127.0.0.1", () => {
  const url = `http://127.0.0.1:${PORT}`;
  console.log(`[Sana] Running at ${url}`);
  exec(`start "${url}"`, (err) => { if (err) console.log(`[Sana] Open ${url} in your browser`); });
});

server.on("error", (e) => {
  if (e.code === "EADDRINUSE") console.error(`[Sana] Port ${PORT} in use`);
  else console.error("[Sana] Error:", e.message);
  process.exit(1);
});
'@ | Out-File "$SANA_DIR\src\serve.js" -Encoding utf8

Success "App files written"

# ── Write index.html ──────────────────────────────────────────
$indexHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Sana</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100vw;height:100vh;background:transparent;overflow:hidden;pointer-events:none;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif}
  #sana-invoke-trigger,#sana-sovereign-dialog,#sana-sovereign-host,#sana-portal-panel,#sana-portal-overlay{pointer-events:all}
  #sana-setup{position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:#0a0612;border:1px solid rgba(167,139,250,0.3);border-radius:16px;padding:32px;width:380px;pointer-events:all;text-align:center;color:#f5f0ff}
  #sana-setup h1{font-size:28px;font-weight:800;margin-bottom:8px;background:linear-gradient(135deg,#a78bfa,#34d399);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
  #sana-setup p{font-size:13px;color:#9ca3af;margin-bottom:20px;line-height:1.6}
  #sana-setup input,#sana-setup select{width:100%;padding:10px 14px;background:rgba(255,255,255,0.06);border:1px solid rgba(167,139,250,0.3);border-radius:8px;color:#f5f0ff;font-size:13px;margin-bottom:10px;outline:none}
  #sana-setup button{width:100%;padding:11px;background:linear-gradient(135deg,#7c3aed,#a78bfa);border:none;border-radius:8px;color:#fff;font-size:14px;font-weight:700;cursor:pointer;margin-top:6px}
  #sana-setup .skip{background:transparent;border:1px solid rgba(167,139,250,0.3);color:#9ca3af;margin-top:8px}
</style>
</head>
<body>
<div id="sana-setup">
  <h1>🧠 Sana</h1>
  <p>Educational intelligence that learns how you learn.<br>Let's get started.</p>
  <input type="text"  id="setup-name"    placeholder="Your name (optional)">
  <input type="email" id="setup-email"   placeholder="Email (for cross-app memory)">
  <select id="setup-role">
    <option value="student">I'm a student</option>
    <option value="teacher">I'm a teacher</option>
    <option value="parent">I'm a parent</option>
  </select>
  <input type="text" id="setup-subject" placeholder="Main subject (e.g. Cybersecurity)">
  <button onclick="startSana()">Start Sana</button>
  <button class="skip" onclick="startSana(true)">Skip — just launch</button>
</div>
<script src="sana-bundle-v11.js"></script>
<script>
function startSana(skip){
  var subject=document.getElementById('setup-subject').value.trim()||'General';
  var email=document.getElementById('setup-email').value.trim();
  var setup=document.getElementById('sana-setup');
  setup.style.transition='opacity 0.4s';setup.style.opacity='0';
  setTimeout(function(){setup.remove();},400);
  try{localStorage.setItem('sana-subject',subject);localStorage.setItem('sana-email',email);}catch(e){}
  window._sanaInvokeConfig={appId:'sana-desktop',subject:subject,floatingTrigger:true,keyboardTrigger:true};
  if(typeof SanaInvoke!=='undefined')SanaInvoke.init(window._sanaInvokeConfig);
  if(typeof SanaMind!=='undefined')SanaMind.init();
  if(typeof SanaCognitive!=='undefined')SanaCognitive.init();
  if(typeof SanaEthics!=='undefined')SanaEthics.init();
  if(typeof SanaVoice!=='undefined')SanaVoice.init();
  if(typeof SanaAdapt!=='undefined')SanaAdapt.init();
  if(typeof SanaSecurity!=='undefined')SanaSecurity.init();
  setTimeout(function(){
    if(typeof SanaVoice!=='undefined')SanaVoice.characterSpeak('session_start',{uid:email||'local'});
    if(typeof SanaInvoke!=='undefined')SanaInvoke.invoke('auto');
  },800);
}
</script>
</body>
</html>
'@
$indexHtml | Out-File "$SANA_DIR\src\index.html" -Encoding utf8
Success "Interface written"

# ── Install dependencies ──────────────────────────────────────
Step "Installing dependencies"

Set-Location $SANA_DIR

Log "Installing npm packages..."
npm install --silent 2>$null
if ($LASTEXITCODE -ne 0) { npm install }

Log "Installing Electron (this may take a moment)..."
$electronJob = Start-Job {
  Set-Location $using:SANA_DIR
  npm install electron --save-dev --silent 2>$null
}
$elapsed = 0
while ($electronJob.State -eq "Running" -and $elapsed -lt 90) {
  Start-Sleep 3
  $elapsed += 3
}
if ($electronJob.State -eq "Running") {
  Stop-Job $electronJob
  Warn "Electron install slow — will use server mode"
}
Remove-Job $electronJob -Force

Success "Dependencies installed"

# ── Create 'sana' command ─────────────────────────────────────
Step "Creating launch command"

$batchContent = @"
@echo off
cd /d "$SANA_DIR"
if exist node_modules\.bin\electron.cmd (
  node_modules\.bin\electron.cmd src\main.js %*
) else (
  node src\serve.js %*
)
"@

# Try to add to user PATH
$userBinDir = "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps"
if (Test-Path $userBinDir) {
  $batchContent | Out-File "$userBinDir\sana.cmd" -Encoding ascii
  Success "Command installed: sana"
} else {
  $batchContent | Out-File "$SANA_DIR\sana.cmd" -Encoding ascii
  Warn "Run '$SANA_DIR\sana.cmd' to start Sana in future"
}

# ── Start Sana ────────────────────────────────────────────────
Step "Starting Sana"

$electronBin = "$SANA_DIR\node_modules\.bin\electron.cmd"
$startArgs   = if (Test-Path $electronBin) {
  @{ FilePath = $electronBin; ArgumentList = "src\main.js" }
} else {
  @{ FilePath = "node"; ArgumentList = "src\serve.js" }
}

$proc = Start-Process @startArgs `
  -WorkingDirectory $SANA_DIR `
  -WindowStyle Hidden `
  -PassThru

$proc.Id | Out-File "$SANA_DIR\data\sana.pid" -Encoding ascii

Start-Sleep 2

# Open browser
Start-Process "http://127.0.0.1:$SANA_PORT"

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  Sana is running." -ForegroundColor Green
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Browser:  http://127.0.0.1:$SANA_PORT" -ForegroundColor Cyan
Write-Host "  Shortcut: Alt+S  (or click the 🧠 button)" -ForegroundColor Cyan
Write-Host "  Logs:     $SANA_DIR\logs\sana.log" -ForegroundColor Cyan
Write-Host "  Stop:     Close the browser window or end the process" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Sana is observing. Start working." -ForegroundColor Magenta
Write-Host ""
