#!/usr/bin/env node
const fs = require('fs')
const path = require('path')

const repo = path.resolve(__dirname, '..')
const src = path.join(repo, 'dist', 'main.lynx.bundle')
if (!fs.existsSync(src)) {
  console.error(`Bundle not found at ${src}. Run \`pnpm build:native\` first.`)
  process.exit(1)
}

const targets = [
  path.join(repo, 'ios', 'LynxTemplate', 'bundle', 'main.lynx.bundle'),
  path.join(repo, 'android', 'app', 'src', 'main', 'assets', 'main.lynx.bundle'),
]

for (const dest of targets) {
  fs.mkdirSync(path.dirname(dest), { recursive: true })
  fs.copyFileSync(src, dest)
  console.log(`Copied → ${dest}`)
}
