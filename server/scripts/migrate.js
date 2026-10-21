const path = require('path');
const dotenv = require('dotenv');

// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '..', '..', '.env') });

const { initializeMySQL, getPool } = require('../_disabled_sync/db');

async function run() {
  console.log('🚀 Running MySQL migration & table initialization...');
  try {
    await initializeMySQL();
    console.log('✅ MySQL tables successfully migrated & verified!');
    const pool = getPool();
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

run();
