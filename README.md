{
  "name": "sana",
  "version": "1.0.0",
  "description": "Sana Educational Intelligence",
  "main": "src/serve.js",
  "bin": {
    "sana": "./sana-cli.js"
  },
  "scripts": {
    "start":   "node src/serve.js",
    "stop":    "node sana-cli.js stop",
    "status":  "node sana-cli.js status"
  },
  "dependencies": {
    "ws":      "^8.16.0",
    "open":    "^9.1.0"
  },
  "engines": {
    "node": ">=18.0.0"
  },
  "keywords": ["education", "ai", "accessibility"],
  "license": "UNLICENSED"
}
