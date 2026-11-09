const pino = require('pino');

// Structured JSON logger.
// In development, pipe output through pino-pretty for readable logs:
//   node src/server.js | npx pino-pretty
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  base: { service: 'fixboard-api' },
});

module.exports = logger;
