const express = require('express');
const router = express.Router();
const navigationController = require('../controllers/navigationController');
const auth = require('../middleware/auth');

router.post('/route', auth, navigationController.computeRoute);
router.post('/geocode', auth, navigationController.geocodeAddress);

module.exports = router;
