const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

// ─── GET /api/items — Fetch all items ───
router.get('/', async (req, res) => {
  try {
    const db = getPool();
    const [rows] = await db.execute('SELECT * FROM items ORDER BY created_at DESC');
    
    // Parse reminder_offsets from JSON string back to array
    const items = rows.map(row => ({
      ...row,
      reminderOffsets: safeParseJSON(row.reminder_offsets, [3]),
      expiryDate: row.expiry_date,
      photoUri: row.photo_uri,
      statusChangedAt: row.status_changed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
    
    res.json({ success: true, data: items });
  } catch (err) {
    console.error('GET /api/items error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET /api/items/:id — Fetch single item ───
router.get('/:id', async (req, res) => {
  try {
    const db = getPool();
    const [rows] = await db.execute('SELECT * FROM items WHERE id = ?', [req.params.id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Item not found' });
    }
    
    const row = rows[0];
    const item = {
      ...row,
      reminderOffsets: safeParseJSON(row.reminder_offsets, [3]),
      expiryDate: row.expiry_date,
      photoUri: row.photo_uri,
      statusChangedAt: row.status_changed_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
    
    res.json({ success: true, data: item });
  } catch (err) {
    console.error('GET /api/items/:id error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /api/items — Create or upsert an item ───
router.post('/', async (req, res) => {
  try {
    const db = getPool();
    const item = req.body;
    
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
    
    res.json({ success: true, message: 'Item saved' });
  } catch (err) {
    console.error('POST /api/items error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── PUT /api/items/:id — Update an item ───
router.put('/:id', async (req, res) => {
  try {
    const db = getPool();
    const item = req.body;
    
    const [result] = await db.execute(`
      UPDATE items SET
        name = ?, category = ?, expiry_date = ?, photo_uri = ?,
        quantity = ?, unit = ?, location = ?, notes = ?,
        reminder_offsets = ?, status = ?, status_changed_at = ?, updated_at = ?
      WHERE id = ?
    `, [
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
      item.updatedAt || new Date().toISOString(),
      req.params.id,
    ]);
    
    res.json({ success: true, message: 'Item updated', affectedRows: result.affectedRows });
  } catch (err) {
    console.error('PUT /api/items/:id error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── DELETE /api/items/:id — Delete an item ───
router.delete('/:id', async (req, res) => {
  try {
    const db = getPool();
    await db.execute('DELETE FROM items WHERE id = ?', [req.params.id]);
    res.json({ success: true, message: 'Item deleted' });
  } catch (err) {
    console.error('DELETE /api/items/:id error:', err.message);
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
