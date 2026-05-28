const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');
const auth = require('../middleware/auth');

// Ánh xạ các API Focus Session yêu cầu về sessionController
router.post('/', auth, sessionController.createSession);
router.get('/', auth, sessionController.getAllSessions);
router.get('/stats', auth, sessionController.getStats);

module.exports = router;
