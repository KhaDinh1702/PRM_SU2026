const Project = require('../models/Project');
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');

// GET /api/projects
exports.getProjects = async (req, res) => {
    try {
        const userId = req.user.id;
        const projects = await Project.find({
            $or: [
                { owner: userId },
                { members: userId }
            ]
        }).populate('owner', 'name email').populate('members', 'name email').sort({ createdAt: -1 });
        res.status(200).json(projects);
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
        }).populate('owner', 'name email').populate('members', 'name email');

        if (!project) {
            return res.status(404).json({ error: 'Dự án không tồn tại hoặc bạn không có quyền xem' });
        }

        // Tính toán thông tin bổ sung: số lượng task, tiến độ
        const totalTasks = await Task.countDocuments({ project: projectId });
        const completedTasks = await Task.countDocuments({ project: projectId, status: 'Completed' });
        const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

        res.status(200).json({
            project,
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

        if (project.members.includes(newMember._id)) {
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

            if (!project.members.includes(req.user.id)) {
                project.members.push(req.user.id);
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

        const tasks = await Task.find({ project: projectId }).sort({ createdAt: -1 });
        res.status(200).json(tasks);
    } catch (error) {
        console.error('Lỗi trong projectController.getProjectTasks:', error);
        res.status(500).json({ error: error.message });
    }
};
