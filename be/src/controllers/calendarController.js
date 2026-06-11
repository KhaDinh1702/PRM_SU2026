const Event = require('../models/Event');
const Task = require('../models/Task');

const userTaskScope = (userId) => ({
    $or: [
        { user: userId },
        { assignedTo: userId },
        { createdBy: userId }
    ]
});

const taskSourceType = (task) => {
    if (task.sourceType) return task.sourceType;
    if (task.project) return 'project';
    if (task.scheduleId) return 'schedule';
    return 'personal';
};

const reminderAtForTask = (task) => {
    if (!task.notificationEnabled || !task.reminderType || task.reminderType === 'none') return null;
    const due = new Date(task.deadline || task.dueDate);
    if (Number.isNaN(due.getTime())) return null;

    const offsets = {
        at_time: 0,
        '15_min_before': 15,
        '30_min_before': 30,
        '1_hour_before': 60,
        '1_day_before': 1440,
        custom: task.reminderOffset || 0
    };
    const minutes = offsets[task.reminderType] ?? 0;
    return new Date(due.getTime() - minutes * 60 * 1000);
};

// GET /api/calendar/events
exports.getEvents = async (req, res) => {
    try {
        const { start, end } = req.query;
        const userId = req.user.id;

        const eventQuery = { user: userId };
        const taskQuery = {
            ...userTaskScope(userId),
            deadline: { $ne: null }
        };

        if (start && end) {
            const startDate = new Date(start);
            const endDate = new Date(end);

            eventQuery.startTime = { $gte: startDate, $lte: endDate };
            taskQuery.deadline = { $gte: startDate, $lte: endDate };
        }

        const [events, tasks] = await Promise.all([
            Event.find(eventQuery)
                .select('title description startTime endTime type')
                .sort({ startTime: 1 })
                .lean(),
            Task.find(taskQuery)
                .select('title description deadline dueDate dueTime sourceType project scheduleId status priority reminderType reminderOffset notificationEnabled')
                .populate({ path: 'project', select: 'name', options: { lean: true } })
                .sort({ deadline: 1 })
                .lean()
        ]);

        const formattedEvents = events.map(event => ({
            id: event._id,
            title: event.title,
            description: event.description,
            start: event.startTime,
            end: event.endTime,
            type: event.type,
            source: 'event'
        }));

        const formattedTasks = tasks.map(task => ({
            id: task._id,
            title: `[TASK DEADLINE] ${task.title}`,
            description: task.description || `Priority: ${task.priority}`,
            start: task.deadline,
            end: task.deadline,
            type: 'reminder',
            source: 'task',
            sourceType: taskSourceType(task),
            projectName: task.project?.name || null,
            status: task.status,
            priority: task.priority,
            dueTime: task.dueTime,
            reminderType: task.reminderType,
            reminderOffset: task.reminderOffset,
            notificationEnabled: task.notificationEnabled,
            reminderAt: reminderAtForTask(task)
        }));

        const schedule = [...formattedEvents, ...formattedTasks].sort((a, b) => new Date(a.start) - new Date(b.start));

        res.status(200).json(schedule);
    } catch (error) {
        console.error('Error in calendarController.getEvents:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/calendar/events
exports.createEvent = async (req, res) => {
    try {
        const { title, description, startTime, endTime, type } = req.body;

        if (!title || !startTime || !endTime) {
            return res.status(400).json({ error: 'Title, start time, and end time are required' });
        }

        if (new Date(startTime) > new Date(endTime)) {
            return res.status(400).json({ error: 'Start time must be before end time' });
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
        console.error('Error in calendarController.createEvent:', error);
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
            return res.status(404).json({ error: 'Event not found or you do not have permission.' });
        }

        if (title !== undefined) event.title = title;
        if (description !== undefined) event.description = description;
        if (startTime !== undefined) event.startTime = startTime;
        if (endTime !== undefined) event.endTime = endTime;
        if (type !== undefined) event.type = type;

        if (new Date(event.startTime) > new Date(event.endTime)) {
            return res.status(400).json({ error: 'Start time must be before end time' });
        }

        await event.save();
        res.status(200).json(event);
    } catch (error) {
        console.error('Error in calendarController.updateEvent:', error);
        res.status(500).json({ error: error.message });
    }
};

// DELETE /api/calendar/events/:eventId
exports.deleteEvent = async (req, res) => {
    try {
        const { eventId } = req.params;

        const event = await Event.findOneAndDelete({ _id: eventId, user: req.user.id });
        if (!event) {
            return res.status(404).json({ error: 'Event not found or you do not have permission.' });
        }

        res.status(200).json({ message: 'Event deleted successfully' });
    } catch (error) {
        console.error('Error in calendarController.deleteEvent:', error);
        res.status(500).json({ error: error.message });
    }
};
