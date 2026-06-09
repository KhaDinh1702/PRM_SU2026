const Task = require('../models/Task');
const Session = require('../models/Session');

const userTaskScope = (userId) => ({
    $or: [
        { user: userId },
        { assignedTo: userId },
        { createdBy: userId }
    ]
});

// GET /api/analytics/reports
exports.getReports = async (req, res) => {
    try {
        const { range } = req.query;
        const userId = req.user.id;

        const start = new Date();
        const end = new Date();

        if (range === 'day') {
            start.setHours(0, 0, 0, 0);
            end.setHours(23, 59, 59, 999);
        } else if (range === 'month') {
            start.setDate(start.getDate() - 30);
            start.setHours(0, 0, 0, 0);
        } else {
            start.setDate(start.getDate() - 7);
            start.setHours(0, 0, 0, 0);
        }

        const taskScope = userTaskScope(userId);
        const totalTasks = await Task.countDocuments({
            ...taskScope,
            createdAt: { $gte: start, $lte: end }
        });

        const completedTasks = await Task.countDocuments({
            ...taskScope,
            status: 'Completed',
            createdAt: { $gte: start, $lte: end }
        });

        const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

        const focusSessions = await Session.find({
            user: userId,
            mode: 'Focus',
            completedAt: { $gte: start, $lte: end }
        });

        const totalFocusSeconds = focusSessions.reduce((total, session) => total + session.durationSeconds, 0);
        const focusSessionsCount = focusSessions.length;

        const dailyStats = [];
        const tempDate = new Date(start);

        while (tempDate <= end) {
            const dayStart = new Date(tempDate);
            dayStart.setHours(0, 0, 0, 0);
            const dayEnd = new Date(tempDate);
            dayEnd.setHours(23, 59, 59, 999);

            const dayTasksCount = await Task.countDocuments({
                ...taskScope,
                status: 'Completed',
                updatedAt: { $gte: dayStart, $lte: dayEnd }
            });

            const daySessions = await Session.find({
                user: userId,
                mode: 'Focus',
                completedAt: { $gte: dayStart, $lte: dayEnd }
            });
            const dayFocusMinutes = Math.round(daySessions.reduce((total, s) => total + s.durationSeconds, 0) / 60);

            dailyStats.push({
                date: dayStart.toISOString().split('T')[0],
                completedTasks: dayTasksCount,
                focusMinutes: dayFocusMinutes
            });

            tempDate.setDate(tempDate.getDate() + 1);
        }

        res.status(200).json({
            summary: {
                totalTasksCreated: totalTasks,
                completedTasksCount: completedTasks,
                completionRatePercentage: completionRate,
                totalFocusTimeMinutes: Math.round(totalFocusSeconds / 60),
                totalFocusSessionsCount: focusSessionsCount
            },
            dailyStats
        });
    } catch (error) {
        console.error('Error in analyticsController.getReports:', error);
        res.status(500).json({ error: error.message });
    }
};
