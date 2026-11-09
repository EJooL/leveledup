const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

async function initDatabase() {
  console.log('🔄 Memulai inisialisasi database LeveledUp...');

  const host = process.env.DB_HOST || 'localhost';
  const port = parseInt(process.env.DB_PORT || '3306', 10);
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';
  const database = process.env.DB_NAME || 'leveledup_db';

  console.log(`📡 Mencoba menghubungkan ke MySQL di ${host}:${port} sebagai user "${user}"...`);

  let connection;
  try {
    // 1. Connect without database first to ensure database can be created
    connection = await mysql.createConnection({
      host,
      port,
      user,
      password,
      multipleStatements: true,
    });
    console.log('✅ Berhasil terhubung ke server MySQL.');

    // 2. Read schema.sql file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    // 3. Execute schema
    console.log(`📄 Menjalankan script skema DDL dari ${schemaPath}...`);
    await connection.query(schemaSql);
    console.log(`✅ Database "${database}" dan seluruh tabel berhasil dibuat / disinkronkan!`);

    // 4. Verify tables
    await connection.query(`USE \`${database}\``);
    const [tables] = await connection.query('SHOW TABLES');
    console.log('\n📋 Daftar Tabel yang Aktif:');
    tables.forEach((row) => {
      console.log(`   - ${Object.values(row)[0]}`);
    });

    // 5. Verify default access code
    const [codes] = await connection.query('SELECT code, description, max_uses, times_used, is_active FROM access_codes');
    console.log('\n🎟️  Kode Promo / Akses Aktif:');
    codes.forEach((c) => {
      console.log(`   - [${c.code}] ${c.description} (Tersisa: ${c.max_uses - c.times_used} dari ${c.max_uses})`);
    });

    console.log('\n🎉 Inisialisasi Database Selesai dengan Sukses!');
  } catch (err) {
    console.error('\n❌ Gagal menginisialisasi database:');
    console.error(`   Pesan error: ${err.message}`);
    console.log('\n💡 Panduan untuk XAMPP phpMyAdmin:');
    console.log('   1. Pastikan modul MySQL dan Apache di XAMPP Control Panel sudah berstatus "Running" (berwarna hijau).');
    console.log('   2. Buka phpMyAdmin di browser: http://localhost/phpmyadmin');
    console.log('   3. Jika port 3306 bertabrakan dengan MySQL Service Windows lain, matikan service "MySQL80" di services.msc atau sesuaikan DB_PORT di backend/.env.');
    console.log('   4. Anda juga bisa langsung mengimpor file backend/sql/schema.sql secara manual melalui tab "Import" di phpMyAdmin!');
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

if (require.main === module) {
  initDatabase();
}

module.exports = initDatabase;

