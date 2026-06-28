const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const paymentController = require('../controllers/paymentController');

router.get('/plans', paymentController.listPlans);
router.post('/payos/create-link', auth, paymentController.createPayOSPaymentLink);
router.post('/payos/webhook', paymentController.handlePayOSWebhook);
router.get('/:orderCode/status', auth, paymentController.getPaymentStatus);

module.exports = router;
