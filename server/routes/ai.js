// ─── Dateora Gemini AI Proxy Router ───
// Handles POST /api/ai/scan with rate limiting, input validation, and Gemini API fallback.

const express = require('express');
const rateLimit = require('express-rate-limit');

const router = express.Router();

// ─── Configuration from Environment ───
const getGeminiApiKey = () => (process.env.GEMINI_API_KEY || '').trim();
const getGeminiModel = () => (process.env.GEMINI_MODEL || 'gemini-3.5-flash').trim();
const getGeminiFallbackModel = () => (process.env.GEMINI_FALLBACK_MODEL || 'gemini-3.5-flash-lite').trim();
const DAILY_SCAN_LIMIT = parseInt(process.env.DAILY_SCAN_LIMIT || '8', 10);
const GLOBAL_DAILY_SCAN_CAP = parseInt(process.env.GLOBAL_DAILY_SCAN_CAP || '1200', 10);

// ─── In-Memory Rate Limiting & Usage Tracking ───
// Note: In-memory store resets on server restart/redeploy (e.g. Render free tier spin-down).
// For future multi-instance production scale, Redis or PostgreSQL will back this store.
const deviceScans = new Map(); // key: deviceId -> { count: number, date: string }
let globalScans = { count: 0, date: getUtcDateString() };

function getUtcDateString() {
  return new Date().toISOString().split('T')[0];
}

function checkAndResetDailyLimits(deviceId) {
  const today = getUtcDateString();

  // Reset global count if day changed
  if (globalScans.date !== today) {
    globalScans = { count: 0, date: today };
  }

  // Check or initialize device count
  let record = deviceScans.get(deviceId);
  if (!record || record.date !== today) {
    record = { count: 0, date: today };
    deviceScans.set(deviceId, record);
  }

  return { record, today };
}

// ─── IP Burst Rate Limiter (express-rate-limit) ───
// Prevents rapid-fire automated spam attacks
const burstLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // max 10 scan requests per minute per IP
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return res.status(429).json({
      error: 'RATE_LIMITED',
      message: 'Too many scan requests from this IP. Please wait a minute before trying again.',
      remaining: 0,
    });
  },
});

// ─── Helper: Determine Image MIME Type ───
function detectMimeType(image) {
  if (image.mimeType && typeof image.mimeType === 'string') {
    const clean = image.mimeType.toLowerCase();
    if (['image/jpeg', 'image/jpg', 'image/png', 'image/webp'].includes(clean)) {
      return clean === 'image/jpg' ? 'image/jpeg' : clean;
    }
  }

  // Check image name extension if provided
  if (image.name && typeof image.name === 'string') {
    const ext = image.name.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.webp')) return 'image/webp';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
  }

  // Check base64 magic bytes
  if (typeof image.data === 'string' && image.data.length > 10) {
    const prefix = image.data.substring(0, 15);
    if (prefix.startsWith('/9j/')) return 'image/jpeg';
    if (prefix.startsWith('iVBORw0KGgo')) return 'image/png';
    if (prefix.startsWith('UklGR')) return 'image/webp';
  }

  return null;
}

// ─── Helper: Call Gemini API ───
async function callGeminiApi({ model, apiKey, prompt, images }) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const parts = [{ text: prompt || 'Identify product name, category, and expiry date.' }];

  for (const img of images) {
    parts.push({
      inlineData: {
        mimeType: img.detectedMime,
        data: img.data,
      },
    });
  }

  const payload = {
    contents: [{ parts }],
    generationConfig: {
      temperature: 0.1,
      responseMimeType: 'application/json',
    },
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  return response;
}

// ─── GET /api/ai/health — Lightweight AI health endpoint ───
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Dateora AI Proxy operational',
    timestamp: new Date().toISOString(),
  });
});

// ─── POST /api/ai/scan — Proxy Gemini Vision Scan ───
router.post('/scan', burstLimiter, async (req, res) => {
  // 1. Device identification
  const rawDeviceId = req.headers['x-device-id'];
  const deviceId = (typeof rawDeviceId === 'string' && rawDeviceId.trim().length > 0)
    ? rawDeviceId.trim()
    : (req.ip || 'unknown_device');

  const { record } = checkAndResetDailyLimits(deviceId);

  // 2. Enforce Global Quota Cap
  if (globalScans.count >= GLOBAL_DAILY_SCAN_CAP) {
    return res.status(429).json({
      error: 'RATE_LIMITED',
      message: 'Global daily AI quota reached. Please try again tomorrow or enter details manually.',
      remaining: 0,
    });
  }

  // 3. Enforce Per-Device Daily Limit
  if (record.count >= DAILY_SCAN_LIMIT) {
    return res.status(429).json({
      error: 'RATE_LIMITED',
      message: 'Aaj ke free scans khatam ho gaye. Kal wapas aao ya manual entry karo.',
      remaining: 0,
    });
  }

  // 4. Validate Input: images array
  const { images, prompt } = req.body || {};
  if (!images || !Array.isArray(images) || images.length === 0 || images.length > 2) {
    return res.status(400).json({
      error: 'INVALID_INPUT',
      message: 'Request must contain an array of 1 or 2 images.',
    });
  }

  // Validate each image
  const preparedImages = [];
  for (let i = 0; i < images.length; i++) {
    const img = images[i];
    if (!img || typeof img.data !== 'string' || img.data.trim().length === 0) {
      return res.status(400).json({
        error: 'INVALID_INPUT',
        message: `Image at index ${i} is missing base64 data.`,
      });
    }

    const detectedMime = detectMimeType(img);
    if (!detectedMime) {
      return res.status(400).json({
        error: 'INVALID_INPUT',
        message: 'Only JPEG, PNG, or WebP images are supported.',
      });
    }

    preparedImages.push({
      data: img.data.trim(),
      detectedMime,
    });
  }

  // 5. Verify Server API Key Configuration
  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    return res.status(503).json({
      error: 'AI_UNAVAILABLE',
      message: 'AI scanning is not configured on the server. Please enter details manually.',
    });
  }

  // 6. Call Gemini API with 1 fallback attempt on 429/5xx
  const primaryModel = getGeminiModel();
  const fallbackModel = getGeminiFallbackModel();
  let upstreamResponse = null;
  let usedModel = primaryModel;

  try {
    upstreamResponse = await callGeminiApi({
      model: primaryModel,
      apiKey,
      prompt,
      images: preparedImages,
    });

    // If 429 or 5xx, try fallback model once
    if (upstreamResponse.status === 429 || upstreamResponse.status >= 500) {
      if (fallbackModel && fallbackModel !== primaryModel) {
        usedModel = fallbackModel;
        try {
          upstreamResponse = await callGeminiApi({
            model: fallbackModel,
            apiKey,
            prompt,
            images: preparedImages,
          });
        } catch (_) {
          // Fallback also failed
        }
      }
    }
  } catch (netErr) {
    console.error('❌ Network error contacting Gemini:', netErr.message);
    return res.status(503).json({
      error: 'AI_UNAVAILABLE',
      message: 'Could not reach AI services. Please check your internet connection.',
    });
  }

  if (!upstreamResponse || !upstreamResponse.ok) {
    const status = upstreamResponse ? upstreamResponse.status : 503;
    let errBody = '';
    try {
      errBody = await upstreamResponse.text();
      console.error(`❌ Upstream Gemini Error [${status}]:`, errBody);
    } catch (_) {}

    if (status === 429) {
      return res.status(429).json({
        error: 'RATE_LIMITED',
        message: 'Upstream AI capacity limit reached. Please wait a moment and try again.',
        remaining: Math.max(0, DAILY_SCAN_LIMIT - record.count),
      });
    }
    return res.status(503).json({
      error: 'AI_UNAVAILABLE',
      message: 'AI service temporarily unavailable. Please try again or enter details manually.',
    });
  }

  let data;
  try {
    data = await upstreamResponse.json();
  } catch (_) {
    return res.status(503).json({
      error: 'AI_UNAVAILABLE',
      message: 'Failed to process AI response. Please try again.',
    });
  }

  // 7. Successful scan: update quotas
  record.count += 1;
  globalScans.count += 1;
  const remaining = Math.max(0, DAILY_SCAN_LIMIT - record.count);

  return res.json({
    remaining,
    dailyLimit: DAILY_SCAN_LIMIT,
    model: usedModel,
    candidates: data.candidates || [],
  });
});

// ─── POST /api/ai/barcode — Resolve product metadata from barcode using Gemini ───
router.post('/barcode', burstLimiter, async (req, res) => {
  const { barcode } = req.body || {};
  if (!barcode || typeof barcode !== 'string' || barcode.trim().length === 0) {
    return res.status(400).json({
      error: 'INVALID_INPUT',
      message: 'Barcode string is required.',
    });
  }

  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    return res.status(503).json({
      error: 'AI_UNAVAILABLE',
      message: 'AI scanning is not configured on the server.',
    });
  }

  const cleanBarcode = barcode.trim();
  const prompt = `Identify the retail consumer product for this barcode: "${cleanBarcode}".
Return a strictly valid JSON object with:
- "productName": string or null (clean product name including brand if known, e.g. "Dove Cream Beauty Bathing Bar")
- "brand": string or null
- "category": string or null (one of: groceries, dairy, pantry, beverages, medicine, skincare, household)
- "quantity": number or null
- "unit": string or null (e.g. g, ml, kg, l, pcs)
If the exact product is not known with high confidence, set "productName": null and guess the most likely "category" based on GS1 prefix or standard packaging.`;

  try {
    const primaryModel = getGeminiModel();
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${primaryModel}:generateContent?key=${apiKey}`;

    const upstreamResponse = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json',
        },
      }),
    });

    if (!upstreamResponse.ok) {
      const errText = await upstreamResponse.text();
      console.error(`❌ Upstream Barcode Error [${upstreamResponse.status}]:`, errText);
      return res.status(502).json({ error: 'UPSTREAM_ERROR' });
    }

    const data = await upstreamResponse.json();
    const rawText = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    let parsed = null;
    if (rawText) {
      try {
        parsed = JSON.parse(rawText);
      } catch (_) {}
    }

    return res.json({
      barcode: cleanBarcode,
      product: parsed,
    });
  } catch (err) {
    console.error('❌ Server Barcode Exception:', err.message);
    return res.status(500).json({ error: 'SERVER_ERROR', message: err.message });
  }
});

module.exports = {
  router,
  checkAndResetDailyLimits,
  deviceScans,
  globalScans,
  DAILY_SCAN_LIMIT,
  GLOBAL_DAILY_SCAN_CAP,
};
