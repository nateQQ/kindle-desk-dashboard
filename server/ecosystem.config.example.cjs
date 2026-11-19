// pm2: `pm2 start ecosystem.config.example.cjs && pm2 save`
// Use an ecosystem file instead of `pm2 start usage-server.mjs`: pm2 mishandles script paths that contain spaces.
module.exports = { apps: [{ name: 'kindle-usage', script: './usage-server.mjs', cwd: __dirname, interpreter: 'node', autorestart: true }] };
