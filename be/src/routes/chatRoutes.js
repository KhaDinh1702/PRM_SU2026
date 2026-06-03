const express = require('express');
const router = express.Router({ mergeParams: true });
const auth = require('../middleware/auth');
const Message = require('../models/Message');
const Project = require('../models/Project');

// GET /api/projects/:projectId/messages
// Fetch messages for a specific project
router.get('/', auth, async (req, res) => {
    try {
        const { projectId } = req.params;

        // Check if the project exists and the user is a member/owner
        const project = await Project.findById(projectId);
        if (!project) {
            return res.status(404).json({ error: 'Project not found' });
        }

        const isMember = project.members.includes(req.user._id) || project.owner.equals(req.user._id);
        if (!isMember) {
            return res.status(403).json({ error: 'Access denied. You are not a member of this project.' });
        }

        const messages = await Message.find({ project: projectId })
            .populate('sender', 'name email profile')
            .sort({ createdAt: 1 })
            .limit(100); // Limit to last 100 messages for now

        res.json(messages);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
