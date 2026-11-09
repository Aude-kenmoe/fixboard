const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const multer = require('multer');
const { pinoHttp } = require('pino-http');
const rateLimit = require('express-rate-limit');
const authRoutes = require('./routes/authRoutes');
const postsRoutes = require('./routes/postsRoutes');
const tagsRoutes = require('./routes/tagsRoutes');
const notificationsRoutes = require('./routes/notificationsRoutes');
const { uploadsDir, corsOrigin } = require('./config/env');
const pool = require('./db/pool');
const logger = require('./utils/logger');

const app = express();

// ── Security headers (HSTS, X-Frame-Options, CSP, etc.) ──────────────────────
app.use(helmet());

// ── Structured request logging ─────────────────────────────────────────────
app.use(
  pinoHttp({
    logger,
    // Skip noisy health-check logs in normal operation
    autoLogging: { ignore: (req) => req.url === '/health' },
  })
);

// ── CORS ──────────────────────────────────────────────────────────────────────
// Set CORS_ORIGIN env var to a specific origin in production, e.g.:
//   CORS_ORIGIN=https://fixboard.ridgelinecloud.io
app.use(cors({ origin: corsOrigin, credentials: true }));

// ── Body parsing ──────────────────────────────────────────────────────────────
app.use(express.json());

// ── Request ID (log correlation) ──────────────────────────────────────────────
// Node 20 exposes crypto.randomUUID() as a global — no import needed.
app.use((req, res, next) => {
  req.requestId = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  next();
});

// ── Health check ──────────────────────────────────────────────────────────────
// Checks DB connectivity so readiness probes catch real database outages.
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true, db: 'up' });
  } catch {
    res.status(503).json({ ok: false, db: 'down' });
  }
});

// ── Auth rate limiting ─────────────────────────────────────────────────────
// Limits login / signup to 20 attempts per IP per 15-minute window.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});

// ── Static file serving ───────────────────────────────────────────────────────
app.use('/uploads', express.static(uploadsDir));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/auth', authLimiter, authRoutes);
app.use('/posts', postsRoutes);
app.use('/tags', tagsRoutes);
app.use('/notifications', notificationsRoutes);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// ── Global error handler ──────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    const message =
      err.code === 'LIMIT_FILE_SIZE' ? 'File is too large (max 8MB)' : err.message;
    return res.status(400).json({ error: message });
  }
  const log = req.log || logger;
  log.error({ err, requestId: req.requestId }, 'Unhandled error');
  res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;
