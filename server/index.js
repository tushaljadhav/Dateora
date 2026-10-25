const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const dotenv = require('dotenv');
const path = require('path');

// Load .env from project root if present
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const { router: aiRoutes } = require('./routes/ai');

const app = express();
const PORT = process.env.PORT || process.env.SERVER_PORT || 3001;

// ─── Security & Standard Middleware ───
app.use(helmet({
  contentSecurityPolicy: false, // Allows inline styles in root landing card
}));
app.use(cors());
app.use(express.json({ limit: '6.5mb' }));

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
        <div style="display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;">
          <a class="btn" href="/api/health">Check /api/health</a>
          <a class="btn" style="background: rgba(16, 185, 129, 0.2); border: 1px solid #10b981; color: #34d399;" href="/privacy">View Privacy Policy</a>
        </div>
      </div>
    </body>
    </html>
  `);
});

const { renderPrivacyPolicyHtml } = require('./privacy_html');

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Official App Favicon / Logo Endpoint ───
app.get(['/favicon.png', '/favicon.ico', '/assets/favicon.png', '/logo/favicon.png'], (req, res) => {
  const p = path.join(__dirname, 'favicon.png');
  res.setHeader('Content-Type', 'image/png');
  res.sendFile(p);
});

// ─── Official Public Privacy Policy (Google Play Console URL) ───
app.get(['/privacy', '/privacy-policy'], (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(renderPrivacyPolicyHtml());
});

// ─── Gemini AI Vision Proxy Route ───
app.use('/api/ai', aiRoutes);

// ─── Disabled Cloud Sync Routes (v1: No Auth) ───
// Cloud sync routes and remote MySQL database initialization are disabled in v1.
// Preserved under server/_disabled_sync/ for re-enabling with user auth + login.
// app.use('/api/items', itemRoutes);
// app.use('/api/settings', settingsRoutes);
// app.use('/api/sync', syncRoutes);

// ─── Start server ───
function start() {
  try {
    app.listen(PORT, () => {
      console.log(`🚀 Dateora API server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('❌ Failed to start server:', err.message);
    process.exit(1);
  }
}

start();
