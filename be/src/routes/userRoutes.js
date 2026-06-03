const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');

router.get('/profile', auth, userController.getProfile);
router.put('/profile', auth, userController.updateProfile);
router.get('/', auth, userController.getAllUsers);

// GET /api/users/me - Lấy thông tin user hiện tại (bao gồm username)
router.get('/me', auth, async (req, res) => {
    try {
        const User = require('../models/User');
        const user = await User.findById(req.user.id).select('-password');
        if (!user) return res.status(404).json({ error: 'User not found' });

        const now = new Date();
        let changesThisMonth = 0;
        if (user.usernameChangedAt) {
            const lastChange = new Date(user.usernameChangedAt);
            const sameMonth = lastChange.getMonth() === now.getMonth() &&
                              lastChange.getFullYear() === now.getFullYear();
            if (sameMonth) changesThisMonth = user.usernameChangeCount || 0;
        }

        res.json({
            id: user._id,
            email: user.email,
            name: user.name || '',
            username: user.username || '',
            phone: user.phone || '',
            profile: user.profile,
            usernameChangesThisMonth: changesThisMonth,
            usernameChangesRemaining: Math.max(0, 2 - changesThisMonth),
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// PUT /api/users/username - Đổi username (tối đa 2 lần/tháng)
router.put('/username', auth, async (req, res) => {
    try {
        const User = require('../models/User');
        const { username } = req.body;

        if (!username || !username.trim()) {
            return res.status(400).json({ error: 'Username không được để trống' });
        }

        const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
        if (!usernameRegex.test(username.trim())) {
            return res.status(400).json({ error: 'Username chỉ chứa chữ cái, số, dấu gạch dưới (3-20 ký tự)' });
        }

        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ error: 'User not found' });

        // Kiểm tra giới hạn 2 lần/tháng
        const now = new Date();
        let changesThisMonth = 0;
        if (user.usernameChangedAt) {
            const lastChange = new Date(user.usernameChangedAt);
            const sameMonth = lastChange.getMonth() === now.getMonth() &&
                              lastChange.getFullYear() === now.getFullYear();
            if (sameMonth) changesThisMonth = user.usernameChangeCount || 0;
        }

        if (changesThisMonth >= 2) {
            return res.status(429).json({
                error: 'Bạn đã đổi username 2 lần trong tháng này. Thử lại vào tháng sau.',
                changesRemaining: 0,
            });
        }

        // Kiểm tra username đã tồn tại chưa
        const existing = await User.findOne({ username: username.trim(), _id: { $ne: req.user.id } });
        if (existing) {
            return res.status(400).json({ error: 'Username này đã được sử dụng bởi người khác' });
        }

        const newCount = changesThisMonth + 1;
        user.username = username.trim();
        user.usernameChangeCount = newCount;
        user.usernameChangedAt = now;
        await user.save();

        res.json({
            message: 'Đổi username thành công!',
            username: user.username,
            changesThisMonth: newCount,
            changesRemaining: 2 - newCount,
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
