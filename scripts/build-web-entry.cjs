#!/usr/bin/env node
// Builds web/main.ts → dist/web/main.js using esbuild (available via vitest's
// dependency tree). This is separate from the rspeedy web build which only
// produces main.web.bundle (Lynx bundle format, not browser-loadable JS).
'use strict'

const path = require('path')
const esbuild = require('esbuild')

const root = path.resolve(__dirname, '..')

esbuild
  .build({
    entryPoints: [path.join(root, 'web', 'main.ts')],
    bundle: true,
    format: 'esm',
    platform: 'browser',
    // Must be esnext for top-level await support in ESM output
    target: 'esnext',
    outdir: path.join(root, 'dist', 'web'),
    entryNames: '[name]',
    splitting: true,
    // Copy .wasm files as external assets referenced by URL
    loader: { '.wasm': 'file' },
    assetNames: 'static/wasm/[name]-[hash]',
    minify: true,
    conditions: ['import', 'browser'],
    // Mark the heavy async-loaded deps as external — they're already bundled
    // by rspeedy into dist/web/static/js/async/ and dist/web/async/
    external: ['@lynx-js/web-mainthread-apis'],
    logLevel: 'warning',
  })
  .then(() => {
    console.log('web entry built → dist/web/main.js')
  })
  .catch((err) => {
    console.error(err)
    process.exit(1)
  })
