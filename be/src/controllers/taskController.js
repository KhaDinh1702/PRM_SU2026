const Task = require('../models/Task');

// GET /api/tasks
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, project, search } = req.query;
        const query = {
            $or: [
                { user: req.user.id },
                { assignedTo: req.user.id }
            ]
        };

        if (status) query.status = status;
        if (priority) query.priority = priority;
        if (project) {
            query.project = project === 'null' ? null : project;
        }
        if (search) {
            query.title = { $regex: search, $options: 'i' };
        }

        const tasks = await Task.find(query)
            .populate('project', 'name')
            .populate('assignedTo', 'name email')
            .populate('assignedBy', 'name email')
            .sort({ createdAt: -1 });
        res.status(200).json(tasks);
    } catch (error) {
        console.error('Lỗi trong taskController.getTasks:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/tasks
exports.createTask = async (req, res) => {
    try {
        const { title, description, status, priority, deadline, label, project, assignedTo } = req.body;

        if (!title) {
            return res.status(400).json({ error: 'Tiêu đề công việc là bắt buộc' });
        }

        const task = new Task({
            title,
            description,
            status: status || 'Pending',
            priority: priority || 'Medium',
            deadline,
            label,
            project: project || null,
            assignedTo: assignedTo || req.user.id,
            assignedBy: req.user.id,
            user: assignedTo || req.user.id
        });

        await task.save();
        res.status(201).json(task);
    } catch (error) {
        console.error('Lỗi trong taskController.createTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/tasks/:taskId
exports.updateTask = async (req, res) => {
    try {
        const { taskId } = req.params;
        const { title, description, status, priority, deadline, label, project, assignedTo } = req.body;

        const task = await Task.findOne({
            _id: taskId,
            $or: [
                { user: req.user.id },
                { assignedTo: req.user.id }
            ]
        });
        if (!task) {
            return res.status(404).json({ error: 'Công việc không tồn tại hoặc bạn không có quyền chỉnh sửa' });
        }

        const ownsTask = task.user.toString() === req.user.id.toString();
        const assignedTask = task.assignedTo?.toString() === req.user.id.toString();

        if (assignedTask && !ownsTask && Object.keys(req.body).some(key => key !== 'status')) {
            return res.status(403).json({ error: 'Bạn chỉ có thể cập nhật trạng thái task được giao' });
        }

        if (ownsTask && title !== undefined) task.title = title;
        if (ownsTask && description !== undefined) task.description = description;
        if (status !== undefined) task.status = status;
        if (ownsTask && priority !== undefined) task.priority = priority;
        if (ownsTask && deadline !== undefined) task.deadline = deadline;
        if (ownsTask && label !== undefined) task.label = label;
        if (ownsTask && project !== undefined) task.project = project || null;
        if (ownsTask && assignedTo !== undefined) {
            task.assignedTo = assignedTo || req.user.id;
            task.user = assignedTo || req.user.id;
        }

        await task.save();
        res.status(200).json(task);
    } catch (error) {
        console.error('Lỗi trong taskController.updateTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// DELETE /api/tasks/:taskId
exports.deleteTask = async (req, res) => {
    try {
        const { taskId } = req.params;

        const task = await Task.findOneAndDelete({ _id: taskId, user: req.user.id });
        if (!task) {
            return res.status(404).json({ error: 'Công việc không tồn tại hoặc bạn không có quyền xóa' });
        }

        res.status(200).json({ message: 'Xóa công việc thành công' });
    } catch (error) {
        console.error('Lỗi trong taskController.deleteTask:', error);
        res.status(500).json({ error: error.message });
    }
};
