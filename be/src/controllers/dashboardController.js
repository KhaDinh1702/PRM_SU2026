const Task = require('../models/Task');
const Project = require('../models/Project');
const Event = require('../models/Event');
const Session = require('../models/Session');

const userTaskScope = (userId) => ({
    $or: [
        { user: userId },
        { assignedTo: userId },
        { createdBy: userId }
    ]
});

// GET /api/dashboard/summary
exports.getSummary = async (req, res) => {
    try {
        const userId = req.user.id;

        // Home counts the same shared Task records used by Project Detail and Main Tasks.
        const pendingTasksCount = await Task.countDocuments({
            ...userTaskScope(userId),
            status: { $in: ['Pending', 'In Progress'] }
        });
        const completedTasksCount = await Task.countDocuments({
            ...userTaskScope(userId),
            status: 'Completed'
        });

        const now = new Date();
        const nextMeeting = await Event.findOne({
            user: userId,
            type: 'meeting',
            startTime: { $gte: now }
        }).sort({ startTime: 1 });

        const projectsCount = await Project.countDocuments({
            $or: [
                { owner: userId },
                { members: userId }
            ]
        });

        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        const todaySessions = await Session.find({
            user: userId,
            mode: 'Focus',
            completedAt: { $gte: startOfDay, $lte: endOfDay }
        });

        const totalFocusSecondsToday = todaySessions.reduce((total, session) => total + session.durationSeconds, 0);

        res.status(200).json({
            pendingTasks: pendingTasksCount,
            completedTasks: completedTasksCount,
            projects: projectsCount,
            totalFocusTimeTodayMinutes: Math.round(totalFocusSecondsToday / 60),
            nextMeeting: nextMeeting ? {
                id: nextMeeting._id,
                title: nextMeeting.title,
                description: nextMeeting.description,
                startTime: nextMeeting.startTime,
                endTime: nextMeeting.endTime
            } : null
        });
    } catch (error) {
        console.error('Error in dashboardController.getSummary:', error);
        res.status(500).json({ error: error.message });
    }
};
