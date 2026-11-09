require('dotenv').config();
const path = require('path');

const isProduction = process.env.NODE_ENV === 'production';

// Fail fast: refuse to start in production without critical secrets
if (isProduction) {
  const required = ['DATABASE_URL', 'JWT_SECRET'];
  const missing = required.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    console.error(`[startup] Missing required environment variables: ${missing.join(', ')}`);
    process.exit(1);
  }
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL,
  // In production, JWT_SECRET must be set (enforced above). The fallback
  // 'dev-secret' is intentionally weak so tests fail loudly if not overridden.
  jwtSecret: process.env.JWT_SECRET || (isProduction ? null : 'dev-secret'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  uploadsDir: process.env.UPLOADS_DIR || path.join(__dirname, '../../uploads'),
  // Comma-separated origins allowed by CORS, e.g. https://app.example.com
  corsOrigin: process.env.CORS_ORIGIN || '*',
  db: {
    max: parseInt(process.env.DB_POOL_MAX || '10', 10),
    idleTimeoutMillis: parseInt(process.env.DB_POOL_IDLE_TIMEOUT || '30000', 10),
    connectionTimeoutMillis: parseInt(process.env.DB_POOL_CONNECTION_TIMEOUT || '5000', 10),
  },
};
