const Project = require('../models/Project');
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');

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
const isProjectParticipant = (project, userId) => Boolean(getProjectRole(project, userId));

const isUserInProject = (project, userId) => {
    const uid = userId.toString();
    return getId(project.owner) === uid || (project.members || []).some(member => getId(member) === uid);
};

const syncDefaultMemberRole = (project, userId) => {
    const uid = userId.toString();
    const hasRole = (project.memberRoles || []).some(item => getId(item.user) === uid);
    if (!hasRole) {
        project.memberRoles.push({ user: userId, role: 'Member' });
    }
};

// GET /api/projects
exports.getProjects = async (req, res) => {
    try {
        const userId = req.user.id;
        const projects = await Project.find({
            $or: [
                { owner: userId },
                { members: userId }
            ]
        })
            .populate('owner', 'name email')
            .populate('members', 'name email')
            .populate('memberRoles.user', 'name email')
            .sort({ createdAt: -1 })
            .lean();

        const projectIds = projects.map(project => project._id);
        const taskStats = projectIds.length
            ? await Task.aggregate([
                { $match: { project: { $in: projectIds } } },
                {
                    $group: {
                        _id: '$project',
                        totalTasks: { $sum: 1 },
                        completedTasks: {
                            $sum: {
                                $cond: [{ $eq: ['$status', 'Completed'] }, 1, 0]
                            }
                        }
                    }
                }
            ])
            : [];
        const pendingInvites = projectIds.length
            ? await Notification.find({
                relatedId: { $in: projectIds },
                type: 'invitation',
                invitationStatus: 'pending'
            }).select('relatedId user').lean()
            : [];

        const statsByProjectId = taskStats.reduce((acc, item) => {
            const totalTasks = item.totalTasks || 0;
            const completedTasks = item.completedTasks || 0;
            acc[item._id.toString()] = {
                totalTasks,
                completedTasks,
                progressPercentage: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0
            };
            return acc;
        }, {});

        const projectsWithStats = projects.map(project => ({
            project,
            currentUserRole: getProjectRole(project, userId),
            pendingInvitationUserIds: pendingInvites
                .filter(invite => invite.relatedId.toString() === project._id.toString())
                .map(invite => invite.user.toString()),
            stats: statsByProjectId[project._id.toString()] || {
                totalTasks: 0,
                completedTasks: 0,
                progressPercentage: 0
            }
        }));

        res.status(200).json(projectsWithStats);
    } catch (error) {
        console.error('Lỗi trong projectController.getProjects:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/projects
exports.createProject = async (req, res) => {
    try {
        const { name, description, deadline } = req.body;
        if (!name) {
            return res.status(400).json({ error: 'Tên dự án là bắt buộc' });
        }

        const project = new Project({
            name,
            description,
            owner: req.user.id,
            members: [],
            deadline,
            status: 'Active'
        });

        await project.save();
        res.status(201).json(project);
    } catch (error) {
        console.error('Lỗi trong projectController.createProject:', error);
        res.status(500).json({ error: error.message });
    }
};

// GET /api/projects/:projectId
exports.getProjectById = async (req, res) => {
    try {
        const { projectId } = req.params;
        const userId = req.user.id;

        const project = await Project.findOne({
            _id: projectId,
            $or: [
                { owner: userId },
                { members: userId }
            ]
        })
            .populate('owner', 'name email')
            .populate('members', 'name email')
            .populate('memberRoles.user', 'name email');

        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không có quyền xem' });
        }

        // Tính toán thông tin bổ sung: số lượng task, tiến độ
        const totalTasks = await Task.countDocuments({ project: projectId });
        const completedTasks = await Task.countDocuments({ project: projectId, status: 'Completed' });
        const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
        const pendingInvites = await Notification.find({
            relatedId: projectId,
            type: 'invitation',
            invitationStatus: 'pending'
        }).select('user').lean();

        res.status(200).json({
            project,
            currentUserRole: getProjectRole(project, userId),
            pendingInvitationUserIds: pendingInvites.map(invite => invite.user.toString()),
            stats: {
                totalTasks,
                completedTasks,
                progressPercentage: progress
            }
        });
    } catch (error) {
        console.error('Lỗi trong projectController.getProjectById:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/projects/:projectId
exports.updateProject = async (req, res) => {
    try {
        const { projectId } = req.params;
        const { name, description, deadline, status } = req.body;

        const project = await Project.findOne({ _id: projectId, owner: req.user.id });
        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không có quyền chỉnh sửa (chỉ chủ sở hữu được sửa)' });
        }

        if (name !== undefined) project.name = name;
        if (description !== undefined) project.description = description;
        if (deadline !== undefined) project.deadline = deadline;
        if (status !== undefined) project.status = status;

        await project.save();
        res.status(200).json(project);
    } catch (error) {
        console.error('Lỗi trong projectController.updateProject:', error);
        res.status(500).json({ error: error.message });
    }
};

// DELETE /api/projects/:projectId
exports.deleteProject = async (req, res) => {
    try {
        const { projectId } = req.params;

        const project = await Project.findOneAndDelete({ _id: projectId, owner: req.user.id });
        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không có quyền xóa (chỉ chủ sở hữu được xóa)' });
        }

        // Mồ côi các task thuộc project này (hoặc xóa chúng)
        await Task.updateMany({ project: projectId }, { project: null });

        res.status(200).json({ message: 'Xóa dự án thành công' });
    } catch (error) {
        console.error('Lỗi trong projectController.deleteProject:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/projects/:projectId/members (Now sends an invitation)
exports.addMember = async (req, res) => {
    try {
        const { projectId } = req.params;
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email thành viên cần thêm là bắt buộc' });
        }

        const project = await Project.findOne({ _id: projectId, owner: req.user.id });
        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không phải là chủ sở hữu' });
        }

        const newMember = await User.findOne({ email: email.trim().toLowerCase() });
        if (!newMember) {
            return res.status(404).json({ error: 'Người dùng với email này không tồn tại trên hệ thống' });
        }

        if (newMember._id.toString() === project.owner.toString()) {
            return res.status(400).json({ error: 'Chủ sở hữu dự án đã mặc định là thành viên' });
        }

        if ((project.members || []).some(member => getId(member) === newMember._id.toString())) {
            return res.status(400).json({ error: 'Người dùng này đã tham gia dự án từ trước' });
        }

        // Check for existing pending invitation
        const existingInvite = await Notification.findOne({
            user: newMember._id,
            type: 'invitation',
            relatedId: projectId,
            invitationStatus: 'pending'
        });

        if (existingInvite) {
            return res.status(400).json({ error: 'Lời mời đang ở trạng thái chờ' });
        }

        // Create Invitation Notification
        const notification = new Notification({
            title: 'Lời mời tham gia dự án',
            message: `Bạn được mời tham gia dự án "${project.name}" bởi ${req.user.name || req.user.email}`,
            type: 'invitation',
            user: newMember._id,
            sender: req.user.id,
            relatedId: project._id,
            onModel: 'Project'
        });

        await notification.save();

        res.status(200).json({
            message: 'Đã gửi lời mời tham gia dự án',
            invitedUserId: newMember._id,
            notification
        });
    } catch (error) {
        console.error('Lỗi trong projectController.addMember:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/projects/:projectId/invitations/:notificationId/respond
exports.respondToInvitation = async (req, res) => {
    try {
        const { projectId, notificationId } = req.params;
        const { action } = req.body; // 'accept' or 'reject'

        if (!['accept', 'reject'].includes(action)) {
            return res.status(400).json({ error: 'Hành động không hợp lệ' });
        }

        const notification = await Notification.findOne({
            _id: notificationId,
            user: req.user.id,
            type: 'invitation',
            relatedId: projectId,
            invitationStatus: 'pending'
        });

        if (!notification) {
            return res.status(404).json({ error: 'Lời mời không tồn tại hoặc đã được xử lý' });
        }

        if (action === 'accept') {
            const project = await Project.findById(projectId);
            if (!project) {
                return res.status(404).json({ error: 'Dự án không còn tồn tại' });
            }

            if (!(project.members || []).some(member => getId(member) === req.user.id.toString())) {
                project.members.push(req.user.id);
                syncDefaultMemberRole(project, req.user.id);
                await project.save();
            }

            notification.invitationStatus = 'accepted';
            notification.message += ' (Đã chấp nhận)';
        } else {
            notification.invitationStatus = 'rejected';
            notification.message += ' (Đã từ chối)';
        }

        notification.isRead = true;
        await notification.save();

        res.status(200).json({
            message: action === 'accept' ? 'Đã tham gia dự án' : 'Đã từ chối lời mời',
            notification
        });
    } catch (error) {
        console.error('Lỗi trong projectController.respondToInvitation:', error);
        res.status(500).json({ error: error.message });
    }
};

// GET /api/projects/:projectId/tasks
exports.getProjectTasks = async (req, res) => {
    try {
        const { projectId } = req.params;
        const userId = req.user.id;

        const project = await Project.findOne({
            _id: projectId,
            $or: [
                { owner: userId },
                { members: userId }
            ]
        });

        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không có quyền truy cập' });
        }

        const tasks = await Task.find({ project: projectId })
            .populate('assignedTo', 'name email')
            .populate('assignedBy', 'name email')
            .populate('user', 'name email')
            .sort({ createdAt: -1 });
        res.status(200).json(tasks);
    } catch (error) {
        console.error('Lỗi trong projectController.getProjectTasks:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/projects/:projectId/tasks
exports.createProjectTask = async (req, res) => {
    try {
        const { projectId } = req.params;
        const { title, description, priority, deadline, assignedTo } = req.body;

        if (!title) {
            return res.status(400).json({ error: 'Task title is required' });
        }

        const project = await Project.findById(projectId);
        if (!project || !isProjectParticipant(project, req.user.id)) {
            return res.status(404).json({ error: 'Project not found or access denied' });
        }

        if (!canManageProject(project, req.user.id)) {
            return res.status(403).json({ error: 'Only Owner or Manager can assign tasks' });
        }

        const assigneeId = assignedTo || req.user.id;
        if (!isUserInProject(project, assigneeId)) {
            return res.status(400).json({ error: 'Assignee must be a project member' });
        }

        const task = new Task({
            title,
            description,
            priority: priority || 'Medium',
            status: 'Pending',
            deadline,
            dueDate: deadline,
            sourceType: 'project',
            project: projectId,
            assignedTo: assigneeId,
            assignedBy: req.user.id,
            createdBy: req.user.id,
            user: assigneeId
        });

        await task.save();

        if (assigneeId.toString() !== req.user.id.toString()) {
            await Notification.create({
                title: 'New project task',
                message: `You were assigned "${task.title}" in project "${project.name}"`,
                type: 'task',
                user: assigneeId,
                sender: req.user.id,
                relatedId: task._id,
                onModel: 'Task'
            });
        }

        await task.populate('assignedTo', 'name email');
        await task.populate('assignedBy', 'name email');

        res.status(201).json(task);
    } catch (error) {
        console.error('Error in projectController.createProjectTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/projects/:projectId/tasks/:taskId
exports.updateProjectTask = async (req, res) => {
    try {
        const { projectId, taskId } = req.params;
        const { title, description, status, priority, deadline, assignedTo } = req.body;

        const project = await Project.findById(projectId);
        if (!project || !isProjectParticipant(project, req.user.id)) {
            return res.status(404).json({ error: 'Project not found or access denied' });
        }

        const task = await Task.findOne({ _id: taskId, project: projectId });
        if (!task) {
            return res.status(404).json({ error: 'Task not found in this project' });
        }

        const manage = canManageProject(project, req.user.id);
        const isAssignee = getId(task.assignedTo || task.user) === req.user.id.toString();

        if (!manage && !isAssignee) {
            return res.status(403).json({ error: 'You can only update tasks assigned to you' });
        }

        if (!manage && Object.keys(req.body).some(key => key !== 'status')) {
            return res.status(403).json({ error: 'Members can only update task status' });
        }

        const previousAssignee = getId(task.assignedTo || task.user);

        if (status !== undefined) {
            task.status = status;
            task.completedAt = status === 'Completed' ? new Date() : null;
        }
        if (manage) {
            if (title !== undefined) task.title = title;
            if (description !== undefined) task.description = description;
            if (priority !== undefined) task.priority = priority;
            if (deadline !== undefined) {
                task.deadline = deadline;
                task.dueDate = deadline;
            }
            if (assignedTo !== undefined) {
                if (!isUserInProject(project, assignedTo)) {
                    return res.status(400).json({ error: 'Assignee must be a project member' });
                }
                task.assignedTo = assignedTo;
                task.user = assignedTo;
            }
        }

        await task.save();

        const nextAssignee = getId(task.assignedTo || task.user);
        if (manage && assignedTo !== undefined && previousAssignee !== nextAssignee && nextAssignee !== req.user.id.toString()) {
            await Notification.create({
                title: 'Project task reassigned',
                message: `You were assigned "${task.title}" in project "${project.name}"`,
                type: 'task',
                user: nextAssignee,
                sender: req.user.id,
                relatedId: task._id,
                onModel: 'Task'
            });
        }

        await task.populate('assignedTo', 'name email');
        await task.populate('assignedBy', 'name email');

        res.status(200).json(task);
    } catch (error) {
        console.error('Error in projectController.updateProjectTask:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/projects/:projectId/members/:userId/role
exports.updateMemberRole = async (req, res) => {
    try {
        const { projectId, userId } = req.params;
        const { role } = req.body;

        if (!['Manager', 'Member'].includes(role)) {
            return res.status(400).json({ error: 'Invalid role' });
        }

        const project = await Project.findOne({ _id: projectId, owner: req.user.id });
        if (!project) {
            return res.status(403).json({ error: 'Only Owner can change member roles' });
        }

        if (project.owner.toString() === userId.toString()) {
            return res.status(400).json({ error: 'Owner role cannot be changed' });
        }

        if (!isUserInProject(project, userId)) {
            return res.status(404).json({ error: 'User is not a project member' });
        }

        const existingRole = (project.memberRoles || []).find(item => getId(item.user) === userId.toString());
        if (existingRole) {
            existingRole.role = role;
        } else {
            project.memberRoles.push({ user: userId, role });
        }

        await project.save();
        const populated = await Project.findById(projectId)
            .populate('owner', 'name email')
            .populate('members', 'name email')
            .populate('memberRoles.user', 'name email');

        res.status(200).json({
            project: populated,
            currentUserRole: 'Owner'
        });
    } catch (error) {
        console.error('Error in projectController.updateMemberRole:', error);
        res.status(500).json({ error: error.message });
    }
};
