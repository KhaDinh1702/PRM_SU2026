const Session = require('../models/Session');
const mongoose = require('mongoose');

// Create new session
exports.createSession = async (req, res) => {
    try {
        const { mode, durationSeconds } = req.body;
        if (!mode || durationSeconds === undefined) {
            return res.status(400).json({ error: 'Missing required fields: mode, durationSeconds' });
        }
        const session = new Session({ 
            mode, 
            durationSeconds, 
            user: req.user.id 
        });
        const savedSession = await session.save();
        res.status(201).json(savedSession);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Get all sessions sorted by date
exports.getAllSessions = async (req, res) => {
    try {
        const sessions = await Session.find({ user: req.user.id }).sort({ completedAt: -1 }).limit(100);
        res.status(200).json(sessions);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Get aggregate stats
exports.getStats = async (req, res) => {
    try {
        const stats = await Session.aggregate([
            {
                $match: { user: new mongoose.Types.ObjectId(req.user.id) }
            },
            {
                $group: {
                    _id: "$mode",
                    count: { $sum: 1 },
                    totalSeconds: { $sum: "$durationSeconds" }
                }
            }
        ]);

        const formattedStats = {
            totalSessions: 0,
            totalFocusMinutes: 0,
            totalBreakMinutes: 0,
            byMode: {
                'Focus': { count: 0, minutes: 0 },
                'Short Break': { count: 0, minutes: 0 },
                'Long Break': { count: 0, minutes: 0 },
                'Custom': { count: 0, minutes: 0 }
            }
        };

        stats.forEach(stat => {
            const mode = stat._id;
            const minutes = Math.round(stat.totalSeconds / 60);
            formattedStats.totalSessions += stat.count;
            
            if (mode === 'Focus' || mode === 'Custom') {
                formattedStats.totalFocusMinutes += minutes;
            } else if (mode === 'Short Break' || mode === 'Long Break') {
                formattedStats.totalBreakMinutes += minutes;
            }

            formattedStats.byMode[mode] = {
                count: stat.count,
                minutes: minutes
            };
        });

        res.status(200).json(formattedStats);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
