const { Pool } = require('pg');
const { databaseUrl, db } = require('../config/env');

const pool = new Pool({
  connectionString: databaseUrl,
  max: db.max,
  idleTimeoutMillis: db.idleTimeoutMillis,
  connectionTimeoutMillis: db.connectionTimeoutMillis,
});

// Surface unexpected client errors so they don't swallow exceptions silently
pool.on('error', (err) => {
  console.error('Unexpected error on idle DB client', err);
  process.exit(1);
});

module.exports = pool;
