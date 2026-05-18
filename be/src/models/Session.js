const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
    mode: {
        type: String,
        required: true,
        enum: ['Focus', 'Short Break', 'Long Break', 'Custom']
    },
    durationSeconds: {
        type: Number,
        required: true
    },
    completedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Session', sessionSchema);
