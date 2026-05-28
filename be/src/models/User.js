const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Vui lòng cung cấp địa chỉ email hợp lệ']
    },
    phone: {
        type: String,
        unique: true,
        sparse: true,
        trim: true,
        match: [/^[0-9]{10,11}$/, 'Vui lòng cung cấp số điện thoại hợp lệ']
    },
    password: {
        type: String,
        required: true,
        minlength: [6, 'Mật khẩu phải chứa ít nhất 6 ký tự']
    },
    name: {
        type: String,
        trim: true,
        default: ''
    },
    profile: {
        bio: { type: String, default: '' },
        avatarUrl: { type: String, default: '' }
    },
    settings: {
        theme: { type: String, default: 'dark' },
        focusTime: { type: Number, default: 25 }, // minutes
        shortBreak: { type: Number, default: 5 }, // minutes
        longBreak: { type: Number, default: 15 } // minutes
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Pre-save hook to hash password
userSchema.pre('save', async function () {
    if (!this.isModified('password')) return;
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
    } catch (error) {
        throw error;
    }
});

// Compare candidate password
userSchema.methods.comparePassword = async function (candidatePassword) {
    try {
        return await bcrypt.compare(candidatePassword, this.password);
    } catch (error) {
        throw new Error(error);
    }
};

module.exports = mongoose.model('User', userSchema);
