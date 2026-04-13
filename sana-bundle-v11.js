# Sana — One-Command Install

## macOS / Linux
```bash
curl -fsSL https://withnreach.com/Sana | bash
```

## Windows (PowerShell)
```powershell
iwr -useb https://withnreach.com/Sana/install.ps1 | iex
```

## Manual (any platform with Node.js 18+)
```bash
git clone https://withnreach.com/Sana
cd sana
npm install
npm start
```

## Commands
```
sana              Start Sana
sana stop         Stop Sana
sana status       Check if running
sana restart      Restart
sana logs         View live logs
sana update       Update to latest
sana reset        Clear data and restart fresh
sana uninstall    Remove completely
```

## First run
After installation, Sana opens in your browser automatically.
Press **Alt+S** (Option+S on Mac) or click the 🧠 button to call her.

For full OS-level accessibility (observing any app, not just the browser),
grant accessibility permission when prompted on macOS, or see the README
for platform-specific instructions.
