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

// ─── Root & Health check ───
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Dateora API Server</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: #090d16;
          color: #f8fafc;
          margin: 0;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
        }
        .card {
          background: #131c2e;
          border: 1px solid rgba(255, 255, 255, 0.1);
          padding: 2.5rem;
          border-radius: 1.25rem;
          text-align: center;
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
          max-width: 420px;
        }
        .badge {
          display: inline-block;
          background: #10b98120;
          color: #34d399;
          padding: 6px 14px;
          border-radius: 9999px;
          font-size: 0.875rem;
          font-weight: 600;
          margin-bottom: 1rem;
          border: 1px solid #10b98140;
        }
        h1 { margin: 0 0 0.5rem; font-size: 1.75rem; }
        p { color: #94a3b8; font-size: 0.95rem; line-height: 1.5; margin: 0 0 1.5rem; }
        .btn {
          display: inline-block;
          background: #3b82f6;
          color: white;
          text-decoration: none;
          padding: 10px 20px;
          border-radius: 8px;
          font-weight: 500;
          transition: background 0.2s;
        }
        .btn:hover { background: #2563eb; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="badge">● Server Live & Operational</div>
        <h1>Dateora API Server</h1>
        <p>Production backend for Dateora Mobile App. Connected to MySQL database.</p>
        <a class="btn" href="/api/health">Check /api/health</a>
      </div>
    </body>
    </html>
  `);
});

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
