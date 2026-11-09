const app = require('./app');
const { port } = require('./config/env');
const pool = require('./db/pool');
const logger = require('./utils/logger');
const runMigrations = require('./db/migrate');
const seed = require('./db/seed');

async function start() {
  await runMigrations();
  await seed();

  const server = app.listen(port, () => {
    logger.info({ port }, 'FixBoard API listening');
  });

  async function shutdown(signal) {
    logger.info({ signal }, 'Shutdown signal received — draining connections');
    server.close(async () => {
      await pool.end();
      logger.info('Server and DB pool closed. Goodbye.');
      process.exit(0);
    });

    // Force-exit if graceful shutdown stalls after 10 s
    setTimeout(() => {
      logger.error('Graceful shutdown timed out, forcing exit');
      process.exit(1);
    }, 10_000).unref();
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

start().catch((err) => {
  logger.error({ err }, 'Failed to start server');
  process.exit(1);
});
