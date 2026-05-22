const User = require('../models/User');
const jwt = require('jsonwebtoken');

const generateToken = (userId) => {
    return jwt.sign(
        { id: userId }, 
        process.env.JWT_SECRET || 'fallback_secret', 
        { expiresIn: '30d' }
    );
};

// @desc    Đăng ký tài khoản mới
// @route   POST /api/auth/register
exports.register = async (req, res) => {
    try {
        const { email, phone, password } = req.body;

        // Validation cơ bản
        if (!email || !password) {
            return res.status(400).json({ error: 'Email và mật khẩu là bắt buộc' });
        }

        if (password.length < 6) {
            return res.status(400).json({ error: 'Mật khẩu phải chứa ít nhất 6 ký tự' });
        }

        // Kiểm tra định dạng email
        const emailRegex = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: 'Định dạng email không hợp lệ' });
        }

        // Kiểm tra trùng lặp email
        const existingEmail = await User.findOne({ email });
        if (existingEmail) {
            return res.status(400).json({ error: 'Email này đã được sử dụng' });
        }

        // Kiểm tra trùng lặp số điện thoại (nếu cung cấp)
        if (phone) {
            const phoneRegex = /^[0-9]{10,11}$/;
            if (!phoneRegex.test(phone)) {
                return res.status(400).json({ error: 'Số điện thoại không hợp lệ (yêu cầu từ 10-11 chữ số)' });
            }

            const existingPhone = await User.findOne({ phone });
            if (existingPhone) {
                return res.status(400).json({ error: 'Số điện thoại này đã được đăng ký' });
            }
        }

        // Tạo người dùng mới
        const user = new User({ email, phone, password });
        await user.save();

        const token = generateToken(user._id);

        res.status(201).json({
            message: 'Đăng ký tài khoản thành công',
            token,
            user: {
                id: user._id,
                email: user.email,
                phone: user.phone || ''
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// @desc    Đăng nhập
// @route   POST /api/auth/login
exports.login = async (req, res) => {
    try {
        const { emailOrPhone, password } = req.body;

        if (!emailOrPhone || !password) {
            return res.status(400).json({ error: 'Vui lòng cung cấp email/số điện thoại và mật khẩu' });
        }

        // Tìm user theo email hoặc số điện thoại
        const user = await User.findOne({
            $or: [{ email: emailOrPhone.toLowerCase() }, { phone: emailOrPhone }]
        });

        if (!user) {
            return res.status(400).json({ error: 'Tài khoản không tồn tại' });
        }

        // Kiểm tra mật khẩu
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(400).json({ error: 'Mật khẩu không chính xác' });
        }

        const token = generateToken(user._id);

        res.status(200).json({
            message: 'Đăng nhập thành công',
            token,
            user: {
                id: user._id,
                email: user.email,
                phone: user.phone || ''
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
