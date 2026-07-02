const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const subscriptionController = require('../controllers/subscriptionController');

router.get('/me', auth, subscriptionController.getMySubscription);

module.exports = router;
