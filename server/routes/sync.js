const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

/**
 * POST /api/sync/push
 * 
 * Full sync from client → server.
 * Receives all items and settings from the local device and upserts them
 * into MySQL. This is the "push" half of the sync — the client is the
 * source of truth.
 */
router.post('/push', async (req, res) => {
  try {
    const db = getPool();
    const { items, settings } = req.body;
    
    let itemsSynced = 0;
    let settingsSynced = 0;
    
    // Upsert all items
    if (Array.isArray(items)) {
      for (const item of items) {
        await db.execute(`
          INSERT INTO items (id, name, category, expiry_date, photo_uri, quantity, unit, location, notes, reminder_offsets, status, status_changed_at, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            category = VALUES(category),
            expiry_date = VALUES(expiry_date),
            photo_uri = VALUES(photo_uri),
            quantity = VALUES(quantity),
            unit = VALUES(unit),
            location = VALUES(location),
            notes = VALUES(notes),
            reminder_offsets = VALUES(reminder_offsets),
            status = VALUES(status),
            status_changed_at = VALUES(status_changed_at),
            updated_at = VALUES(updated_at)
        `, [
          item.id,
          item.name,
          item.category,
          item.expiryDate,
          item.photoUri || null,
          item.quantity ?? null,
          item.unit || null,
          item.location || null,
          item.notes || null,
          JSON.stringify(item.reminderOffsets || [3]),
          item.status || 'active',
          item.statusChangedAt || null,
          item.createdAt,
          item.updatedAt,
        ]);
        itemsSynced++;
      }
    }
    
    // Upsert settings
    if (settings && typeof settings === 'object') {
      for (const [key, value] of Object.entries(settings)) {
        await db.execute(`
          INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?)
          ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
        `, [key, String(value)]);
        settingsSynced++;
      }
    }
    
    res.json({
      success: true,
      message: 'Sync push complete',
      itemsSynced,
      settingsSynced,
    });
  } catch (err) {
    console.error('POST /api/sync/push error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/sync/pull
 * 
 * Full sync from server → client.
 * Returns all items and settings from MySQL so the client can merge them
 * into local storage.
 */
router.get('/pull', async (req, res) => {
  try {
    const db = getPool();
    
    const [itemRows] = await db.execute('SELECT * FROM items ORDER BY created_at DESC');
    const [settingsRows] = await db.execute('SELECT * FROM app_settings');
    
    const items = itemRows.map(row => ({
      id: row.id,
      name: row.name,
      category: row.category,
      expiryDate: row.expiry_date,
      photoUri: row.photo_uri,
      quantity: row.quantity !== null ? Number(row.quantity) : null,
      unit: row.unit,
      location: row.location,
      notes: row.notes,
      reminderOffsets: safeParseJSON(row.reminder_offsets, [3]),
      status: row.status,
      statusChangedAt: row.status_changed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
    
    const settings = {};
    settingsRows.forEach(row => {
      settings[row.setting_key] = row.setting_value;
    });
    
    res.json({
      success: true,
      data: { items, settings },
      serverTimestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('GET /api/sync/pull error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * DELETE /api/sync/item/:id
 * 
 * Delete a specific item from the remote database (triggered when user
 * deletes locally and the sync service propagates the deletion).
 */
router.delete('/item/:id', async (req, res) => {
  try {
    const db = getPool();
    await db.execute('DELETE FROM items WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Remote item deleted' });
  } catch (err) {
    console.error('DELETE /api/sync/item/:id error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

function safeParseJSON(str, fallback) {
  try {
    return JSON.parse(str);
  } catch {
    return fallback;
  }
}

module.exports = router;
