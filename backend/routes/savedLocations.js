const express = require('express');
const router = express.Router();
const db = require('../db');

/* ---------- GET SAVED LOCATIONS ---------- */
router.get('/:userId', (req, res) => {
  const { userId } = req.params;

  const sql = `
    SELECT id, name, latitude, longitude
    FROM saved_locations
    WHERE user_id = ?
    ORDER BY created_at DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ success: false });
    }
    res.json(results);
  });
});

/* ---------- ADD SAVED LOCATION ---------- */
router.post('/', (req, res) => {
  const { userId, name, latitude, longitude } = req.body;

  if (!userId || !name || !latitude || !longitude) {
    return res.status(400).json({ success: false });
  }

  const sql = `
    INSERT INTO saved_locations (user_id, name, latitude, longitude)
    VALUES (?, ?, ?, ?)
  `;

  db.query(sql, [userId, name, latitude, longitude], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ success: false });
    }
    res.json({ success: true });
  });
});

module.exports = router;
