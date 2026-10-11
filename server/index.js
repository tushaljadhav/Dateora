const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { initializeMySQL } = require('./db');
const itemRoutes = require('./routes/items');
const settingsRoutes = require('./routes/settings');
const syncRoutes = require('./routes/sync');

const app = express();
const PORT = process.env.PORT || process.env.SERVER_PORT || 3001;

// ─── Middleware ───
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ─── Health check ───
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Routes ───
app.use('/api/items', itemRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/sync', syncRoutes);

// ─── Start server ───
async function start() {
  try {
    await initializeMySQL();
    console.log('✅ MySQL connected and tables initialized');

    app.listen(PORT, () => {
      console.log(`🚀 Dateora API server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err.message);
    process.exit(1);
  }
}

start();
