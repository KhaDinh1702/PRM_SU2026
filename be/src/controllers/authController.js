const User = require('../models/User');
const Otp = require('../models/Otp');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

const generateToken = (userId) => {
    return jwt.sign(
        { id: userId }, 
        process.env.JWT_SECRET || 'fallback_secret', 
        { expiresIn: '30d' }
    );
};

// Cấu hình transporter cho Nodemailer sử dụng Gmail
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

// @desc    Gửi mã OTP qua Email
// @route   POST /api/auth/send-otp
exports.sendOtp = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ error: 'Email là bắt buộc' });
        }

        // Kiểm tra định dạng email
        const emailRegex = /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({ error: 'Định dạng email không hợp lệ' });
        }

        // Kiểm tra xem email đã đăng ký chưa
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: 'Email này đã được đăng ký' });
        }

        // Tạo mã OTP gồm 6 chữ số ngẫu nhiên
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Lưu hoặc cập nhật OTP trong DB
        await Otp.findOneAndUpdate(
            { email: email.toLowerCase() },
            { otp, createdAt: new Date() },
            { upsert: true, new: true }
        );

        // Gửi email OTP
        const mailOptions = {
            from: `"Space Timer Support" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: '[Space Timer] Mã xác thực đăng ký tài khoản (OTP)',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                    <h2 style="color: #8B5CF6; text-align: center;">Xác thực tài khoản Space Timer</h2>
                    <p>Chào bạn,</p>
                    <p>Bạn đang thực hiện đăng ký tài khoản trên ứng dụng quản lý năng suất <b>Space Timer</b>.</p>
                    <p>Mã xác thực OTP của bạn là:</p>
                    <div style="background-color: #f1f5f9; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                        <span style="font-size: 28px; font-weight: bold; letter-spacing: 4px; color: #1e293b;">${otp}</span>
                    </div>
                    <p style="color: #64748b; font-size: 14px;">Mã OTP này có hiệu lực trong vòng <b>5 phút</b>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                    <hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 20px 0;">
                    <p style="text-align: center; color: #94a3b8; font-size: 12px;">© 2026 Space Timer. All rights reserved.</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);

        res.status(200).json({ message: 'Mã OTP đã được gửi thành công về email của bạn' });
    } catch (error) {
        console.error('Lỗi trong authController.sendOtp:', error);
        res.status(500).json({ error: 'Không thể gửi email OTP. Vui lòng thử lại sau.' });
    }
};

// @desc    Đăng ký tài khoản mới kèm OTP
// @route   POST /api/auth/register
exports.register = async (req, res) => {
    try {
        const { email, phone, password, name, username, otp } = req.body;

        // Validation cơ bản
        if (!email || !password) {
            return res.status(400).json({ error: 'Email và mật khẩu là bắt buộc' });
        }

        if (!otp) {
            return res.status(400).json({ error: 'Vui lòng cung cấp mã OTP để xác thực' });
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

        // Xác thực mã OTP
        const otpRecord = await Otp.findOne({ email: email.toLowerCase() });
        if (!otpRecord) {
            return res.status(400).json({ error: 'Mã OTP đã hết hạn hoặc không tồn tại. Vui lòng gửi lại.' });
        }

        if (otpRecord.otp !== otp.trim()) {
            return res.status(400).json({ error: 'Mã xác thực OTP không chính xác' });
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

        // Kiểm tra username nếu có
        if (username) {
            const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
            if (!usernameRegex.test(username)) {
                return res.status(400).json({ error: 'Username chỉ chứa chữ cái, số, dấu gạch dưới (3-20 ký tự)' });
            }
            const existingUsername = await User.findOne({ username });
            if (existingUsername) {
                return res.status(400).json({ error: 'Username này đã được sử dụng' });
            }
        }

        // Tạo người dùng mới
        const user = new User({ email, phone, password, name: name || '', username: username || undefined });
        await user.save();

        // Xóa OTP sau khi xác thực thành công
        await Otp.deleteOne({ _id: otpRecord._id });

        const token = generateToken(user._id);

        res.status(201).json({
            message: 'Đăng ký tài khoản thành công',
            token,
            user: {
                id: user._id,
                email: user.email,
                phone: user.phone || '',
                name: user.name || '',
                username: user.username || ''
            }
        });
    } catch (error) {
        console.error('Lỗi trong authController.register:', error);
        res.status(500).json({ error: error.message });
    }
};

// @desc    Đăng nhập
// @route   POST /api/auth/login
exports.login = async (req, res) => {
    try {
        const { emailOrPhone, password } = req.body;

        if (!emailOrPhone || !password) {
            return res.status(400).json({ error: 'Vui lòng cung cấp email, số điện thoại hoặc username và mật khẩu' });
        }

        // Tìm user theo email, số điện thoại hoặc username
        const user = await User.findOne({
            $or: [
                { email: emailOrPhone.toLowerCase() },
                { phone: emailOrPhone },
                { username: emailOrPhone }
            ]
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
                phone: user.phone || '',
                name: user.name || '',
                username: user.username || ''
            }
        });
    } catch (error) {
        console.error('Lỗi trong authController.login:', error);
        res.status(500).json({ error: error.message });
    }
};
