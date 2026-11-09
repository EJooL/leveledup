const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const dotenv = require('dotenv');

dotenv.config();

const { testConnection } = require('./config/db');
const { isAiAvailable } = require('./config/ai');
const { apiLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

// Route imports
const parseRoutes = require('./routes/parseRoutes');
const analyzeRoutes = require('./routes/analyzeRoutes');
const unlockRoutes = require('./routes/unlockRoutes');
const rewriteRoutes = require('./routes/rewriteRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Security & Parsing Middleware
app.use(helmet());
app.use(cors({
  origin: '*', // Allow all origins for mobile app API access
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-device-id'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Apply rate limiting to all /api/ endpoints
app.use('/api/', apiLimiter);

// Health Check Endpoint
app.get('/api/health', async (req, res) => {
  const dbConnected = await testConnection();
  res.status(200).json({
    status: 'ok',
    service: 'LeveledUp Mobile Backend API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    databaseConnected: dbConnected,
    aiEngineAvailable: isAiAvailable(),
    defaultPromoCode: 'LEVELEDUPVIP2026',
  });
});

// Mount Feature API Routes
app.use('/api/parse', parseRoutes);
app.use('/api/analyze', analyzeRoutes);
app.use('/api/unlock', unlockRoutes);
app.use('/api/rewrite', rewriteRoutes);

// 404 Route Handler
app.use((req, res, next) => {
  res.status(404).json({
    error: `Endpoint '${req.method} ${req.originalUrl}' tidak ditemukan.`,
    code: 'NOT_FOUND',
  });
});

// Centralized Error Handling
app.use(errorHandler);

// Start Server if not imported as module
if (require.main === module) {
  app.listen(PORT, async () => {
    console.log(`====================================================`);
    console.log(`🚀 LeveledUp Backend Server running on port ${PORT}`);
    console.log(`📡 Base URL: http://localhost:${PORT}`);
    console.log(`🩺 Health check: http://localhost:${PORT}/api/health`);
    console.log(`====================================================`);
    
    // Test database connection on startup
    await testConnection();
  });
}

module.exports = app;

