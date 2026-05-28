const Task = require('../models/Task');

// GET /api/tasks
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, project, search } = req.query;
        const query = { user: req.user.id };

        if (status) query.status = status;
        if (priority) query.priority = priority;
        if (project) {
            query.project = project === 'null' ? null : project;
        }
        if (search) {
            query.title = { $regex: search, $options: 'i' };
        }

        const tasks = await Task.find(query).populate('project', 'name').sort({ createdAt: -1 });
        res.status(200).json(tasks);
    } catch (error) {
        console.error('Lỗi trong taskController.getTasks:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/tasks
exports.createTask = async (req, res) => {
    try {
        const { title, description, status, priority, deadline, label, project } = req.body;

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
            user: req.user.id
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
        const { title, description, status, priority, deadline, label, project } = req.body;

        const task = await Task.findOne({ _id: taskId, user: req.user.id });
        if (!task) {
            return res.status(404).json({ error: 'Công việc không tồn tại hoặc bạn không có quyền chỉnh sửa' });
        }

        if (title !== undefined) task.title = title;
        if (description !== undefined) task.description = description;
        if (status !== undefined) task.status = status;
        if (priority !== undefined) task.priority = priority;
        if (deadline !== undefined) task.deadline = deadline;
        if (label !== undefined) task.label = label;
        if (project !== undefined) task.project = project || null;

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
