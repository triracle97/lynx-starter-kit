#!/usr/bin/env node
const os = require('os')
const port = process.env.LYNX_DEV_PORT || 3000
const nets = os.networkInterfaces()
for (const name of Object.keys(nets)) {
  for (const net of nets[name] || []) {
    if (net.family === 'IPv4' && !net.internal) {
      console.log(`http://${net.address}:${port}/main.lynx.bundle`)
      process.exit(0)
    }
  }
}
console.error('No non-internal IPv4 interface found. Connect to a network and retry.')
process.exit(1)
