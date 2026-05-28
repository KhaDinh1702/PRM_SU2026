const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
    try {
        const authHeader = req.header('Authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Không tìm thấy token xác thực. Quyền truy cập bị từ chối.' });
        }

        const token = authHeader.replace('Bearer ', '');
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
        
        req.user = decoded;
        next();
    } catch (error) {
        console.error('Lỗi trong middleware auth:', error);
        res.status(401).json({ error: 'Token xác thực không hợp lệ hoặc đã hết hạn.' });
    }
};

module.exports = auth;
