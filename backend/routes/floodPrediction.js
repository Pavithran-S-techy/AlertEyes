const express = require('express');
const axios = require('axios');

const router = express.Router();

/*
  GET all grid predictions
*/
router.get('/predict-all-grids', async (req, res) => {
  try {
    const response = await axios.get(
      'http://localhost:8000/predict-all-grids'
    );

    res.json(response.data);

  } catch (error) {
    console.error('❌ ML Service Error:', error.message);
    res.status(500).json({
      error: 'Unable to connect to ML service'
    });
  }
});

/*
  DEV prediction mode
*/
router.post('/predict-dev', async (req, res) => {
  try {
    const response = await axios.post(
      'http://localhost:8000/predict-dev',
      req.body
    );

    res.json(response.data);

  } catch (error) {
    console.error('❌ ML Dev Error:', error.message);
    res.status(500).json({
      error: 'Unable to connect to ML dev service'
    });
  }
});

module.exports = router;