const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'leveledup_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
});

// Helper function to test connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log(`[Database] Connected successfully to MySQL database "${process.env.DB_NAME || 'leveledup_db'}" on ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '3306'}`);
    connection.release();
    return true;
  } catch (error) {
    console.warn(`[Database Warning] Could not connect to MySQL: ${error.message}`);
    console.warn(`[Database Warning] Please ensure MySQL is running and check your .env credentials.`);
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};

