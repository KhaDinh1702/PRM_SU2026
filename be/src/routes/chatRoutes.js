const express = require('express');
const router = express.Router({ mergeParams: true });
const rateLimit = require('express-rate-limit');
const auth = require('../middleware/auth');
const Message = require('../models/Message');
const Project = require('../models/Project');

const chatMessagesLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    standardHeaders: true,
    legacyHeaders: false
});

// Helper: dùng toString() để so sánh ObjectId với string (tránh lỗi type mismatch từ JWT)
// JWT được tạo với { id: userId } → dùng req.user.id (KHÔNG phải req.user._id)
const isProjectMember = (project, userId) => {
    if (!userId) return false;
    const uid = userId.toString();
    const ownerMatch = project.owner.toString() === uid;
    const memberMatch = project.members.some(m => m.toString() === uid);
    return ownerMatch || memberMatch;
};

// GET /api/projects/:projectId/messages
router.get('/', chatMessagesLimiter, auth, async (req, res) => {
    try {
        const { projectId } = req.params;
        const limit = Math.min(parseInt(req.query.limit, 10) || 50, 50);

        const project = await Project.findById(projectId);
        if (!project) {
            return res.status(404).json({ error: 'Project not found' });
        }

        if (!isProjectMember(project, req.user.id)) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this project.' });
        }

        const messages = await Message.find({ project: projectId })
            .populate('sender', 'name email username profile')
            .sort({ createdAt: -1 })
            .limit(limit)
            .lean();

        res.json(messages.reverse());
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// POST /api/projects/:projectId/messages
router.post('/', chatMessagesLimiter, auth, async (req, res) => {
    try {
        const { projectId } = req.params;
        const { text } = req.body;

        if (!text || !text.trim()) {
            return res.status(400).json({ error: 'Message text is required' });
        }

        const project = await Project.findById(projectId);
        if (!project) {
            return res.status(404).json({ error: 'Project not found' });
        }

        if (!isProjectMember(project, req.user.id)) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this project.' });
        }

        // Lưu tin nhắn vào DB
        const newMessage = new Message({
            project: projectId,
            sender: req.user.id,
            text: text.trim(),
        });
        await newMessage.save();
        await newMessage.populate('sender', 'name email username profile');

        // Broadcast qua Socket.IO cho tất cả thành viên trong room
        const io = req.app.get('io');
        if (io) {
            io.to(projectId).emit('receiveMessage', newMessage);
        }

        res.status(201).json(newMessage);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
