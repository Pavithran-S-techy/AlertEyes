const mysql = require('mysql2');

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

db.connect((err) => {
  if (err) {
    console.error('❌ MySQL connection failed:', err);
    return;
  }
  console.log('✅ MySQL connected');
  db.query('SELECT DATABASE()', (err, res) => {
    console.log('📌 Connected DB:', res[0]['DATABASE()']);
  });
});

module.exports = db;
