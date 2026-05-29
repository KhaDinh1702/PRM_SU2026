const User = require('../models/User');

// GET /api/users/profile
exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ error: 'Người dùng không tồn tại' });
        }
        res.status(200).json(user);
    } catch (error) {
        console.error('Lỗi trong userController.getProfile:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/user/profile (hoặc /api/users/profile)
exports.updateProfile = async (req, res) => {
    try {
        const { name, phone, bio, avatarUrl, settings } = req.body;
        
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ error: 'Người dùng không tồn tại' });
        }

        // Cập nhật các trường
        if (name !== undefined) user.name = name;
        if (phone !== undefined) {
            // Kiểm tra trùng SĐT nếu thay đổi
            if (phone !== user.phone && phone !== '') {
                const existingPhone = await User.findOne({ phone });
                if (existingPhone) {
                    return res.status(400).json({ error: 'Số điện thoại này đã được đăng ký bởi tài khoản khác' });
                }
            }
            user.phone = phone === '' ? undefined : phone;
        }
        
        if (user.profile === undefined) user.profile = {};
        if (bio !== undefined) user.profile.bio = bio;
        if (avatarUrl !== undefined) user.profile.avatarUrl = avatarUrl;

        if (user.settings === undefined) user.settings = {};
        if (settings) {
            if (settings.theme !== undefined) user.settings.theme = settings.theme;
            if (settings.focusTime !== undefined) user.settings.focusTime = settings.focusTime;
            if (settings.shortBreak !== undefined) user.settings.shortBreak = settings.shortBreak;
            if (settings.longBreak !== undefined) user.settings.longBreak = settings.longBreak;
        }

        await user.save();
        
        // Trả về thông tin không gồm password
        const updatedUser = await User.findById(req.user.id).select('-password');
        res.status(200).json({
            message: 'Cập nhật thông tin thành công',
            user: updatedUser
        });
    } catch (error) {
        console.error('Lỗi trong userController.updateProfile:', error);
        res.status(500).json({ error: error.message });
    }
};

// GET /api/users
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find()
            .select('_id name email profile.avatarUrl')
            .sort({ createdAt: -1 });

        res.status(200).json(users);
    } catch (error) {
        console.error('Lỗi trong userController.getAllUsers:', error);
        res.status(500).json({ error: error.message });
    }
};
