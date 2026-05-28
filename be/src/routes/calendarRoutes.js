const express = require('express');
const router = express.Router();
const calendarController = require('../controllers/calendarController');
const auth = require('../middleware/auth');

router.get('/events', auth, calendarController.getEvents);
router.post('/events', auth, calendarController.createEvent);
router.put('/events/:eventId', auth, calendarController.updateEvent);
router.delete('/events/:eventId', auth, calendarController.deleteEvent);

module.exports = router;
