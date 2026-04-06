require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const db = require('./db');

const savedLocationsRoutes = require('./routes/savedLocations');

const floodZonesRoutes = require('./routes/floodZones');

const app = express();
const PORT = process.env.PORT || 5000;

/* ---------- MIDDLEWARE ---------- */
app.use(cors()); // allow Flutter Web
app.use(express.json());

app.use('/saved-locations', savedLocationsRoutes);

app.use('/flood-zones', floodZonesRoutes);

/* ---------- TEST ROUTE ---------- */
app.get('/', (req, res) => {
  res.send('Flood AI Backend Running');
});

const floodPredictionRoutes = require('./routes/floodPrediction');

app.use('/flood-prediction', floodPredictionRoutes);


/* ---------- SIGNUP ---------- */
app.post('/signup', async (req, res) => {
  const { name, email, password } = req.body;

  console.log('📩 Signup request:', req.body);

  if (!name || !email || !password) {
    return res.json({ success: false, message: 'All fields required' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const sql =
    'INSERT INTO users (name, email, password) VALUES (?, ?, ?)';

  db.query(sql, [name, email, hashedPassword], (err, result) => {
    if (err) {
        console.error('❌ INSERT ERROR:', err);
      if (err.code === 'ER_DUP_ENTRY') {
        return res.json({
          success: false,
          message: 'Email already exists',
        });
      }
      return res.json({ success: false, message: 'Signup failed' });
    }
    console.log('✅ Inserted user ID:', result.insertId);
    res.json({ success: true });
  });
});

/* ---------- LOGIN ---------- */
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  const sql = 'SELECT * FROM users WHERE email = ?';

  db.query(sql, [email], async (err, results) => {
    if (err || results.length === 0) {
      return res.json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const user = results[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    });
  });
});

/* ---------- START SERVER ---------- */
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
