const Event = require('../models/Event');
const Task = require('../models/Task');

// GET /api/calendar/events
exports.getEvents = async (req, res) => {
    try {
        const { start, end } = req.query;
        const userId = req.user.id;

        const eventQuery = { user: userId };
        const taskQuery = { user: userId, deadline: { $ne: null } };

        if (start && end) {
            const startDate = new Date(start);
            const endDate = new Date(end);
            
            eventQuery.startTime = { $gte: startDate, $lte: endDate };
            taskQuery.deadline = { $gte: startDate, $lte: endDate };
        }

        // Lấy danh sách sự kiện lịch
        const events = await Event.find(eventQuery).sort({ startTime: 1 });

        // Lấy các task có deadline làm lịch trình deadline
        const tasks = await Task.find(taskQuery).populate('project', 'name').sort({ deadline: 1 });

        // Gộp hai danh sách thành một lịch trình trực quan
        const formattedEvents = events.map(event => ({
            id: event._id,
            title: event.title,
            description: event.description,
            start: event.startTime,
            end: event.endTime,
            type: event.type, // 'meeting', 'reminder', 'other'
            source: 'event'
        }));

        const formattedTasks = tasks.map(task => ({
            id: task._id,
            title: `[TASK DEADLINE] ${task.title}`,
            description: task.description || `Độ ưu tiên: ${task.priority}`,
            start: task.deadline,
            end: task.deadline,
            type: 'reminder',
            source: 'task',
            status: task.status,
            priority: task.priority
        }));

        const schedule = [...formattedEvents, ...formattedTasks].sort((a, b) => new Date(a.start) - new Date(b.start));

        res.status(200).json(schedule);
    } catch (error) {
        console.error('Lỗi trong calendarController.getEvents:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/calendar/events
exports.createEvent = async (req, res) => {
    try {
        const { title, description, startTime, endTime, type } = req.body;

        if (!title || !startTime || !endTime) {
            return res.status(400).json({ error: 'Tiêu đề, thời gian bắt đầu và kết thúc là bắt buộc' });
        }

        if (new Date(startTime) > new Date(endTime)) {
            return res.status(400).json({ error: 'Thời gian bắt đầu phải trước thời gian kết thúc' });
        }

        const event = new Event({
            title,
            description,
            startTime,
            endTime,
            type: type || 'reminder',
            user: req.user.id
        });

        await event.save();
        res.status(201).json(event);
    } catch (error) {
        console.error('Lỗi trong calendarController.createEvent:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/calendar/events/:eventId
exports.updateEvent = async (req, res) => {
    try {
        const { eventId } = req.params;
        const { title, description, startTime, endTime, type } = req.body;

        const event = await Event.findOne({ _id: eventId, user: req.user.id });
        if (!event) {
            return res.status(404).json({ error: 'Sự kiện không tồn tại hoặc bạn không có quyền sửa' });
        }

        if (title !== undefined) event.title = title;
        if (description !== undefined) event.description = description;
        if (startTime !== undefined) event.startTime = startTime;
        if (endTime !== undefined) event.endTime = endTime;
        if (type !== undefined) event.type = type;

        if (new Date(event.startTime) > new Date(event.endTime)) {
            return res.status(400).json({ error: 'Thời gian bắt đầu phải trước thời gian kết thúc' });
        }

        await event.save();
        res.status(200).json(event);
    } catch (error) {
        console.error('Lỗi trong calendarController.updateEvent:', error);
        res.status(500).json({ error: error.message });
    }
};

// DELETE /api/calendar/events/:eventId
exports.deleteEvent = async (req, res) => {
    try {
        const { eventId } = req.params;

        const event = await Event.findOneAndDelete({ _id: eventId, user: req.user.id });
        if (!event) {
            return res.status(404).json({ error: 'Sự kiện không tồn tại hoặc bạn không có quyền xóa' });
        }

        res.status(200).json({ message: 'Xóa sự kiện thành công' });
    } catch (error) {
        console.error('Lỗi trong calendarController.deleteEvent:', error);
        res.status(500).json({ error: error.message });
    }
};
