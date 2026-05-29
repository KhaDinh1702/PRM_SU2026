const Notification = require('../models/Notification');

// GET /api/notifications
exports.getNotifications = async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 });
        res.status(200).json(notifications);
    } catch (error) {
        console.error('Lỗi trong notificationController.getNotifications:', error);
        res.status(500).json({ error: error.message });
    }
};

// PUT /api/notifications/:notificationId/read
exports.markAsRead = async (req, res) => {
    try {
        const { notificationId } = req.params;

        const notification = await Notification.findOne({ _id: notificationId, user: req.user.id });
        if (!notification) {
            return res.status(404).json({ error: 'Thông báo không tồn tại hoặc bạn không có quyền truy cập' });
        }

        notification.isRead = true;
        await notification.save();

        res.status(200).json(notification);
    } catch (error) {
        console.error('Lỗi trong notificationController.markAsRead:', error);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/notifications
exports.createNotification = async (req, res) => {
    try {
        const { title, message, type } = req.body;
        if (!title || !message) {
            return res.status(400).json({ error: 'Tiêu đề và nội dung là bắt buộc' });
        }

        const notification = new Notification({
            title,
            message,
            type: type || 'other',
            user: req.user.id
        });

        await notification.save();
        res.status(201).json(notification);
    } catch (error) {
        console.error('Lỗi trong notificationController.createNotification:', error);
        res.status(500).json({ error: error.message });
    }
};
