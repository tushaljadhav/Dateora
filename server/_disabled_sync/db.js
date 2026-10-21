// DISABLED in v1: cloud sync and remote MySQL database have no auth. Re-enable with user auth and login.
const mysql = require('mysql2/promise');

let pool = null;

/**
 * Creates and returns the MySQL connection pool.
 */
function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.MYSQL_HOST,
      port: parseInt(process.env.MYSQL_PORT || '3306', 10),
      user: process.env.MYSQL_USER,
      password: process.env.MYSQL_PASSWORD,
      database: process.env.MYSQL_DATABASE,
      waitForConnections: true,
      connectionLimit: 5,       // Free tier — keep it modest
      queueLimit: 0,
      connectTimeout: 10000,
    });
  }
  return pool;
}

/**
 * Initializes MySQL: tests connection and creates tables if they don't exist.
 */
async function initializeMySQL() {
  const db = getPool();

  // Test the connection
  const conn = await db.getConnection();
  console.log('  📡 Connected to MySQL at', process.env.MYSQL_HOST);
  conn.release();

  // Create tables
  await db.execute(`
    CREATE TABLE IF NOT EXISTS items (
      id VARCHAR(64) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      category VARCHAR(100) NOT NULL,
      expiry_date VARCHAR(20) NOT NULL,
      photo_uri TEXT,
      quantity DECIMAL(10,2),
      unit VARCHAR(50),
      location VARCHAR(255),
      notes TEXT,
      reminder_offsets TEXT NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'active',
      status_changed_at VARCHAR(30),
      created_at VARCHAR(30) NOT NULL,
      updated_at VARCHAR(30) NOT NULL,
      INDEX idx_items_expiry (expiry_date),
      INDEX idx_items_status (status)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  await db.execute(`
    CREATE TABLE IF NOT EXISTS notification_records (
      id VARCHAR(128) PRIMARY KEY,
      item_id VARCHAR(64) NOT NULL,
      fires_at VARCHAR(30) NOT NULL,
      INDEX idx_notifications_item (item_id),
      FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  await db.execute(`
    CREATE TABLE IF NOT EXISTS app_settings (
      setting_key VARCHAR(100) PRIMARY KEY,
      setting_value TEXT NOT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  console.log('  📋 Tables verified/created');
}

module.exports = { getPool, initializeMySQL };
