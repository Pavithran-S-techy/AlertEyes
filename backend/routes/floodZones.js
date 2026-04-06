const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();

// Load GeoJSON ONCE (important for performance)
const filePath = path.join(__dirname, '..', 'data', 'kerala_flood_2018.geojson');
const geojson = JSON.parse(fs.readFileSync(filePath, 'utf8'));

router.get('/', (req, res) => {
  try {
    const { minLat, maxLat, minLng, maxLng } = req.query;

    // If bbox not provided, return empty (prevents overload)
    if (!minLat || !maxLat || !minLng || !maxLng) {
      return res.json({ type: 'FeatureCollection', features: [] });
    }

    const minLatN = parseFloat(minLat);
    const maxLatN = parseFloat(maxLat);
    const minLngN = parseFloat(minLng);
    const maxLngN = parseFloat(maxLng);

    // Filter polygons by bounding box
    const filteredFeatures = geojson.features.filter(feature => {
      if (!feature.geometry || feature.geometry.type !== 'Polygon') return false;

      const coords = feature.geometry.coordinates[0];

      // Check if ANY vertex is inside bbox
      return coords.some(([lng, lat]) =>
        lat >= minLatN &&
        lat <= maxLatN &&
        lng >= minLngN &&
        lng <= maxLngN
      );
    });

    res.json({
      type: 'FeatureCollection',
      features: filteredFeatures,
    });
  } catch (err) {
    console.error('❌ Flood zones error:', err);
    res.status(500).json({ error: 'Failed to load flood zones' });
  }
});

module.exports = router;
