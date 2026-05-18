const express = require('express');
const router = express.Router();
const sessionController = require('../controllers/sessionController');

router.post('/', sessionController.createSession);
router.get('/', sessionController.getAllSessions);
router.get('/stats', sessionController.getStats);

module.exports = router;
