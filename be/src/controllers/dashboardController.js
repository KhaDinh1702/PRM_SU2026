const Task = require('../models/Task');
const Project = require('../models/Project');
const Event = require('../models/Event');
const Session = require('../models/Session');

// GET /api/dashboard/summary
exports.getSummary = async (req, res) => {
    try {
        const userId = req.user.id;

        // 1. Task cần làm (Pending, In Progress) và Task đã hoàn thành
        const pendingTasksCount = await Task.countDocuments({ 
            user: userId, 
            status: { $in: ['Pending', 'In Progress'] } 
        });
        const completedTasksCount = await Task.countDocuments({ 
            user: userId, 
            status: 'Completed' 
        });

        // 2. Lịch họp gần nhất (meeting sắp tới)
        const now = new Date();
        const nextMeeting = await Event.findOne({
            user: userId,
            type: 'meeting',
            startTime: { $gte: now }
        }).sort({ startTime: 1 });

        // 3. Project đang tham gia (chủ sở hữu hoặc là thành viên)
        const projectsCount = await Project.countDocuments({
            $or: [
                { owner: userId },
                { members: userId }
            ]
        });

        // 4. Tổng thời gian focus trong ngày hôm nay (tính bằng giây)
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
        console.error('Lỗi trong dashboardController.getSummary:', error);
        res.status(500).json({ error: error.message });
    }
};
