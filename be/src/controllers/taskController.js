const Task = require('../models/Task');
const Project = require('../models/Project');

const getId = (value) => {
    if (!value) return '';
    if (value._id) return value._id.toString();
    return value.toString();
};

const getProjectRole = (project, userId) => {
    const uid = userId.toString();
    if (getId(project.owner) === uid) return 'Owner';

    const roleEntry = (project.memberRoles || []).find(item => getId(item.user) === uid);
    if (roleEntry) return roleEntry.role || 'Member';

    const isMember = (project.members || []).some(member => getId(member) === uid);
    return isMember ? 'Member' : null;
};

const canManageProject = (project, userId) => ['Owner', 'Manager'].includes(getProjectRole(project, userId));

const getManagedProjectIds = async (userId) => {
    const projects = await Project.find({
        $or: [
            { owner: userId },
            { memberRoles: { $elemMatch: { user: userId, role: 'Manager' } } }
        ]
    }).select('_id').lean();

    return projects.map(project => project._id);
};

const taskSourceType = (task) => {
    if (task.sourceType) return task.sourceType;
    if (task.project) return 'project';
    if (task.scheduleId) return 'schedule';
    return 'personal';
};

const normalizeTask = (task) => {
    const plainTask = task.toObject ? task.toObject() : task;
    return {
        ...plainTask,
        sourceType: taskSourceType(plainTask),
        createdBy: plainTask.createdBy || plainTask.assignedBy || plainTask.user,
        dueDate: plainTask.dueDate || plainTask.deadline || null
    };
};

const startOfToday = () => {
    const date = new Date();
    date.setHours(0, 0, 0, 0);
    return date;
};

const endOfToday = () => {
    const date = new Date();
    date.setHours(23, 59, 59, 999);
    return date;
};

const deadlineRangeFilter = (start, end) => ({
    $or: [
        { deadline: { $gte: start, $lte: end } },
        { dueDate: { $gte: start, $lte: end } }
    ]
});

const personalSourceFilter = {
    $and: [
        { $or: [{ sourceType: 'personal' }, { sourceType: { $exists: false } }] },
        { project: null },
        { scheduleId: null }
    ]
};

const projectSourceFilter = {
    $or: [{ sourceType: 'project' }, { project: { $ne: null } }]
};

const scheduleSourceFilter = {
    $or: [{ sourceType: 'schedule' }, { scheduleId: { $ne: null } }]
};

// GET /api/tasks
// Unified inbox: personal, assigned project tasks, created tasks, and managed project tasks.
exports.getTasks = async (req, res) => {
    try {
        const { status, priority, project, search, source, tab, sort } = req.query;
        const managedProjectIds = await getManagedProjectIds(req.user.id);
        const filters = [{
            $or: [
                { user: req.user.id },
                { assignedTo: req.user.id },
                { createdBy: req.user.id },
                ...(managedProjectIds.length ? [{ project: { $in: managedProjectIds } }] : [])
            ]
        }];

        if (status && status !== 'All') filters.push({ status });
        if (priority && priority !== 'All') filters.push({ priority });
        if (project) filters.push({ project: project === 'null' ? null : project });

        if (source === 'personal') filters.push(personalSourceFilter);
        if (source === 'project') filters.push(projectSourceFilter);
        if (source === 'schedule') filters.push(scheduleSourceFilter);

        if (tab) {
            const now = new Date();
            const todayStart = startOfToday();
            const todayEnd = endOfToday();

            if (tab === 'Today') filters.push(deadlineRangeFilter(todayStart, todayEnd));
            if (tab === 'Upcoming') {
                filters.push({
                    $or: [
                        { deadline: { $gt: todayEnd } },
                        { dueDate: { $gt: todayEnd } }
                    ]
                });
            }
            if (tab === 'Overdue') {
                filters.push({
                    status: { $ne: 'Completed' },
                    $or: [
                        { deadline: { $lt: now } },
                        { dueDate: { $lt: now } }
                    ]
                });
            }
            if (tab === 'Project') filters.push(projectSourceFilter);
            if (tab === 'Personal') filters.push(personalSourceFilter);
            if (tab === 'Completed') filters.push({ status: 'Completed' });
        }

        if (search) filters.push({ title: { $regex: search, $options: 'i' } });

        const query = filters.length === 1 ? filters[0] : { $and: filters };
        const sortOption = sort === 'deadline'
            ? { deadline: 1, dueDate: 1, updatedAt: -1 }
            : sort === 'priority'
                ? { priority: -1, updatedAt: -1 }
                : { updatedAt: -1, createdAt: -1 };

        const tasks = await Task.find(query)
            .populate('project', 'name')
            .populate('assignedTo', 'name email')
            .populate('assignedBy', 'name email')
            .populate('createdBy', 'name email')
            .sort(sortOption);

        res.status(200).json(tasks.map(normalizeTask));
    } catch (error) {
        console.error('Error in taskController.getTasks:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/tasks
// Creates personal tasks only. Project tasks must use /api/projects/:projectId/tasks.
exports.createTask = async (req, res) => {
    try {
        const {
            title,
            description,
            status,
            priority,
            deadline,
            label,
            project,
            assignedTo,
            sourceType,
            scheduleId,
            startDate,
            dueDate,
            dueTime,
            reminderType,
            reminderOffset,
            notificationEnabled
        } = req.body;

        if (!title) {
            return res.status(400).json({ error: 'Task title is required' });
        }
        if (project || sourceType === 'project') {
            return res.status(400).json({
                error: 'Project tasks must be created via /api/projects/:projectId/tasks so the same task record stays linked to its project.'
            });
        }
        if (scheduleId || sourceType === 'schedule') {
            return res.status(400).json({
                error: 'Schedule tasks must be created from the schedule flow so the shared task record keeps its schedule context.'
            });
        }

        const task = new Task({
            title,
            description,
            status: status || 'Pending',
            priority: priority || 'Medium',
            deadline: dueDate || deadline,
            label,
            sourceType: 'personal',
            project: null,
            scheduleId: null,
            assignedTo: assignedTo || req.user.id,
            assignedBy: req.user.id,
            createdBy: req.user.id,
            startDate,
            dueDate: dueDate || deadline,
            dueTime,
            reminderType: reminderType || 'none',
            reminderOffset: reminderOffset ?? null,
            notificationEnabled: Boolean(notificationEnabled && (reminderType || 'none') !== 'none'),
            completedAt: status === 'Completed' ? new Date() : null,
            user: assignedTo || req.user.id
        });

        await task.save();
        res.status(201).json(normalizeTask(task));
    } catch (error) {
        console.error('Error in taskController.createTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/tasks/:taskId
// Updates the same task document shown in Project Detail, Home, and Main Tasks.
exports.updateTask = async (req, res) => {
    try {
        const { taskId } = req.params;
        const {
            title,
            description,
            status,
            priority,
            deadline,
            label,
            project,
            assignedTo,
            sourceType,
            scheduleId,
            startDate,
            dueDate,
            dueTime,
            reminderType,
            reminderOffset,
            notificationEnabled
        } = req.body;

        if (project !== undefined || sourceType !== undefined || scheduleId !== undefined) {
            return res.status(400).json({
                error: 'Task source cannot be changed from the main Tasks endpoint. Use the Project or Schedule flow for source-specific changes.'
            });
        }

        const managedProjectIds = await getManagedProjectIds(req.user.id);
        const task = await Task.findOne({
            _id: taskId,
            $or: [
                { user: req.user.id },
                { assignedTo: req.user.id },
                { createdBy: req.user.id },
                ...(managedProjectIds.length ? [{ project: { $in: managedProjectIds } }] : [])
            ]
        }).populate('project');

        if (!task) {
            return res.status(404).json({ error: 'Task not found or you do not have permission.' });
        }

        const ownsTask = getId(task.user) === req.user.id.toString() || getId(task.createdBy) === req.user.id.toString();
        const assignedTask = getId(task.assignedTo) === req.user.id.toString();
        const managesProjectTask = task.project ? canManageProject(task.project, req.user.id) : false;
        const canEditFields = ownsTask || managesProjectTask;

        if (assignedTask && !canEditFields && Object.keys(req.body).some(key => key !== 'status')) {
            return res.status(403).json({ error: 'You can only update the status of tasks assigned to you.' });
        }
        if (!assignedTask && !canEditFields && status !== undefined) {
            return res.status(403).json({ error: 'You do not have permission to update this task.' });
        }

        // Sử dụng helper cập nhật task chung
        const { updateTaskFields } = require('../utils/taskHelper');
        updateTaskFields(task, req.body, canEditFields);

        // Riêng ở updateTask chung, nếu gán assignedTo về rỗng thì set mặc định
        if (canEditFields && assignedTo !== undefined && !assignedTo) {
            task.assignedTo = req.user.id;
            task.user = req.user.id;
        }

        await task.save();
        await task.populate('project', 'name');
        await task.populate('assignedTo', 'name email');
        await task.populate('assignedBy', 'name email');
        await task.populate('createdBy', 'name email');

        // Phát Socket.io real-time nếu task thuộc dự án
        if (task.project) {
            const io = req.app.get('io');
            if (io) {
                io.to(task.project._id.toString()).emit('taskUpdated', task);
            }
        }

        res.status(200).json(normalizeTask(task));
    } catch (error) {
        console.error('Error in taskController.updateTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// DELETE /api/tasks/:taskId
exports.deleteTask = async (req, res) => {
    try {
        const { taskId } = req.params;
        const task = await Task.findById(taskId).populate('project');

        if (!task) {
            return res.status(404).json({ error: 'Task not found or you do not have permission.' });
        }

        const ownsTask = getId(task.user) === req.user.id.toString() || getId(task.createdBy) === req.user.id.toString();
        const managesProjectTask = task.project ? canManageProject(task.project, req.user.id) : false;

        // Cho phép cả người tạo task (ownsTask) được quyền xóa task dự án
        if (task.project && !managesProjectTask && !ownsTask) {
            return res.status(403).json({ error: 'You do not have permission to delete this task. Only Owner, Manager, or the creator can delete it.' });
        }
        if (!task.project && !ownsTask) {
            return res.status(403).json({ error: 'You do not have permission to delete this task.' });
        }

        const projectId = task.project ? task.project._id : null;

        await task.deleteOne();

        // Phát Socket.io event delete nếu task thuộc dự án
        if (projectId) {
            const io = req.app.get('io');
            if (io) {
                io.to(projectId.toString()).emit('taskDeleted', { taskId });
            }
        }

        res.status(200).json({ message: 'Task deleted successfully' });
    } catch (error) {
        console.error('Error in taskController.deleteTask:', error);
        res.status(500).json({ error: error.message });
    }
};
