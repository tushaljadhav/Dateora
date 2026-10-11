const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

// ─── GET /api/settings — Fetch all settings ───
router.get('/', async (req, res) => {
  try {
    const db = getPool();
    const [rows] = await db.execute('SELECT * FROM app_settings');
    
    const settings = {};
    rows.forEach(row => {
      settings[row.setting_key] = row.setting_value;
    });
    
    res.json({ success: true, data: settings });
  } catch (err) {
    console.error('GET /api/settings error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── PUT /api/settings — Upsert a setting ───
router.put('/', async (req, res) => {
  try {
    const db = getPool();
    const { key, value } = req.body;
    
    if (!key) {
      return res.status(400).json({ success: false, error: 'key is required' });
    }
    
    await db.execute(`
      INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?)
      ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
    `, [key, String(value)]);
    
    res.json({ success: true, message: `Setting '${key}' saved` });
  } catch (err) {
    console.error('PUT /api/settings error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /api/settings/bulk — Upsert multiple settings at once ───
router.post('/bulk', async (req, res) => {
  try {
    const db = getPool();
    const { settings } = req.body; // { key1: value1, key2: value2, ... }
    
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ success: false, error: 'settings object is required' });
    }
    
    for (const [key, value] of Object.entries(settings)) {
      await db.execute(`
        INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
      `, [key, String(value)]);
    }
    
    res.json({ success: true, message: `${Object.keys(settings).length} settings saved` });
  } catch (err) {
    console.error('POST /api/settings/bulk error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
