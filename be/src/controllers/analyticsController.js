const Task = require('../models/Task');
const Session = require('../models/Session');

// GET /api/analytics/reports
exports.getReports = async (req, res) => {
    try {
        const { range } = req.query; // 'day', 'week', 'month' - mặc định 'week'
        const userId = req.user.id;

        const start = new Date();
        const end = new Date();

        if (range === 'day') {
            start.setHours(0, 0, 0, 0);
            end.setHours(23, 59, 59, 999);
        } else if (range === 'month') {
            // Lùi lại 30 ngày
            start.setDate(start.getDate() - 30);
            start.setHours(0, 0, 0, 0);
        } else {
            // week (mặc định) - lùi lại 7 ngày
            start.setDate(start.getDate() - 7);
            start.setHours(0, 0, 0, 0);
        }

        // 1. Thống kê Tasks
        const totalTasks = await Task.countDocuments({
            user: userId,
            createdAt: { $gte: start, $lte: end }
        });

        const completedTasks = await Task.countDocuments({
            user: userId,
            status: 'Completed',
            createdAt: { $gte: start, $lte: end }
        });

        const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

        // 2. Thống kê Focus Sessions
        const focusSessions = await Session.find({
            user: userId,
            mode: 'Focus',
            completedAt: { $gte: start, $lte: end }
        });

        const totalFocusSeconds = focusSessions.reduce((total, session) => total + session.durationSeconds, 0);
        const focusSessionsCount = focusSessions.length;

        // 3. Biểu đồ chi tiết theo từng ngày trong khoảng thời gian
        const dailyStats = [];
        const tempDate = new Date(start);

        while (tempDate <= end) {
            const dayStart = new Date(tempDate);
            dayStart.setHours(0, 0, 0, 0);
            const dayEnd = new Date(tempDate);
            dayEnd.setHours(23, 59, 59, 999);

            const dayTasksCount = await Task.countDocuments({
                user: userId,
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
        console.error('Lỗi trong analyticsController.getReports:', error);
        res.status(500).json({ error: error.message });
    }
};
