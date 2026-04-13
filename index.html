/**
 * Sana Runtime Server
 *
 * Three jobs:
 *   1. HTTP server — serves the bundle and overlay to the browser
 *   2. WebSocket bridge — routes native AX events ↔ browser
 *   3. Process management — PID file, clean shutdown
 *
 * This is the only process that needs to run.
 * The browser tab IS the Sana UI.
 */

'use strict';

const http      = require('http');
const fs        = require('fs');
const path      = require('path');
const WebSocket = require('ws');

// ── Config ─────────────────────────────────────────────────────
const SANA_DIR  = path.resolve(__dirname, '..');
const PORT      = parseInt(process.env.SANA_PORT || '7432');
const WS_PORT   = PORT + 1;   // 7433
const LOG_FILE  = path.join(SANA_DIR, 'logs', 'sana.log');
const PID_FILE  = path.join(SANA_DIR, 'data', 'sana.pid');

// Ensure directories exist
[path.join(SANA_DIR,'logs'), path.join(SANA_DIR,'data')].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

// Write PID
fs.writeFileSync(PID_FILE, String(process.pid));

// ── Logging ────────────────────────────────────────────────────
function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  process.stdout.write(line);
  try { fs.appendFileSync(LOG_FILE, line); } catch(e) {}
}

log(`Sana server starting — PID ${process.pid}`);

// ── MIME types ─────────────────────────────────────────────────
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'application/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png':  'image/png',
  '.ico':  'image/x-icon',
  '.svg':  'image/svg+xml'
};

// ── HTTP server ─────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  // CORS for local development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');

  if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

  // Route: /health → status check
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', pid: process.pid, uptime: process.uptime() }));
    return;
  }

  // Route: /status → full diagnostics (for sana status command)
  if (req.url === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status:    'running',
      pid:       process.pid,
      uptime:    Math.round(process.uptime()),
      memory:    process.memoryUsage().heapUsed,
      port:      PORT,
      wsPort:    WS_PORT,
      rendererConnected: !!rendererWs,
      nativeConnected:   !!nativeWs
    }));
    return;
  }

  // Serve static files
  let urlPath = req.url.split('?')[0];
  if (urlPath === '/') urlPath = '/index.html';

  const filePath = path.join(SANA_DIR, urlPath);
  const realPath = path.resolve(filePath);

  // Security: only serve files within SANA_DIR
  if (!realPath.startsWith(path.resolve(SANA_DIR))) {
    res.writeHead(403); res.end('Forbidden'); return;
  }

  fs.readFile(realPath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404);
        res.end('Not found: ' + urlPath);
      } else {
        res.writeHead(500);
        res.end('Server error');
      }
      return;
    }

    const ext  = path.extname(realPath).toLowerCase();
    const mime = MIME[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': mime });
    res.end(data);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  log(`HTTP server listening on http://127.0.0.1:${PORT}`);
});

// ── WebSocket bridge ────────────────────────────────────────────
let rendererWs = null;
let nativeWs   = null;
const eventBuffer = [];   // holds native events until renderer connects
const MAX_BUFFER  = 100;

const wss = new WebSocket.Server({ port: WS_PORT, host: '127.0.0.1' });

wss.on('connection', (ws, req) => {

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw.toString());

      // ── Renderer (Sana bundle) announces itself ─────────────
      if (msg.type === 'sana:ready') {
        rendererWs = ws;
        log('Renderer connected');
        // Flush buffered native events
        eventBuffer.forEach(m => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(m));
          }
        });
        eventBuffer.length = 0;
        return;
      }

      // ── Native helper announces itself ──────────────────────
      if (msg.type === 'native:ready') {
        nativeWs = ws;
        ws.send(JSON.stringify({ type: 'sana:ready', version: '1.0.0' }));
        log('Native bridge connected — platform: ' + (msg.platform || 'unknown'));
        return;
      }

      // ── Native → Renderer: ax:* events ─────────────────────
      if (msg.type && msg.type.startsWith('ax:')) {
        if (rendererWs && rendererWs.readyState === WebSocket.OPEN) {
          rendererWs.send(raw.toString());
        } else {
          eventBuffer.push(msg);
          if (eventBuffer.length > MAX_BUFFER) eventBuffer.shift();
        }
        return;
      }

      // ── Renderer → Native: sana:* commands ─────────────────
      if (msg.type && msg.type.startsWith('sana:')) {
        if (nativeWs && nativeWs.readyState === WebSocket.OPEN) {
          nativeWs.send(raw.toString());
        }
        return;
      }

    } catch(e) {
      log('WS parse error: ' + e.message);
    }
  });

  ws.on('close', () => {
    if (ws === rendererWs) { rendererWs = null; log('Renderer disconnected'); }
    if (ws === nativeWs)   { nativeWs   = null; log('Native bridge disconnected'); }
  });

  ws.on('error', e => log('WS error: ' + e.message));
});

log(`WebSocket bridge listening on ws://127.0.0.1:${WS_PORT}`);

// ── Open browser ────────────────────────────────────────────────
setTimeout(() => {
  const url = `http://127.0.0.1:${PORT}`;
  const { exec } = require('child_process');
  const cmd = process.platform === 'darwin' ? `open "${url}"` :
              process.platform === 'win32'  ? `start "" "${url}"` :
              `xdg-open "${url}" 2>/dev/null || sensible-browser "${url}"`;

  exec(cmd, err => {
    if (err) log(`Open manually: ${url}`);
    else     log(`Browser opened: ${url}`);
  });
}, 800);

// ── Graceful shutdown ───────────────────────────────────────────
function shutdown(signal) {
  log(`Shutdown signal: ${signal}`);
  try { fs.unlinkSync(PID_FILE); } catch(e) {}
  server.close();
  wss.close();
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));
process.on('uncaughtException', e => log('Uncaught: ' + e.message));
process.on('unhandledRejection', e => log('Unhandled: ' + e));

log('Sana runtime ready');
