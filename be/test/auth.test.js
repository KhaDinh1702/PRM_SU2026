const request = require('supertest');
const express = require('express');
const authRoutes = require('../src/routes/authRoutes');
const User = require('../src/models/User');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

// Mock User Model một cách chi tiết để cô lập unit test khỏi database thật
jest.mock('../src/models/User', () => {
    const mockConstructor = function (data) {
        this._id = '6523e12089b25c3decfb3f9b';
        this.email = data?.email;
        this.phone = data?.phone;
        this.password = data?.password;
        this.save = jest.fn().mockResolvedValue(this);
    };
    
    mockConstructor.findOne = jest.fn();
    return mockConstructor;
});

describe('Authentication API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('POST /api/auth/register', () => {
        test('Đăng ký tài khoản thành công', async () => {
            // Giả lập chưa tồn tại email
            User.findOne = jest.fn().mockResolvedValue(null);

            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com',
                    phone: '0987654321',
                    password: 'password123'
                });

            expect(res.status).toBe(201);
            expect(res.body.message).toContain('Đăng ký tài khoản thành công');
            expect(res.body).toHaveProperty('token');
            expect(res.body.user.email).toBe('test@example.com');
        });

        test('Thất bại khi thiếu trường bắt buộc', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('Email và mật khẩu là bắt buộc');
        });

        test('Thất bại khi email sai định dạng', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'invalid-email',
                    password: 'password123'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('Định dạng email không hợp lệ');
        });

        test('Thất bại khi trùng email', async () => {
            // Giả lập tìm thấy email trùng lặp
            User.findOne = jest.fn().mockResolvedValue({ email: 'test@example.com' });

            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com',
                    password: 'password123'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('Email này đã được sử dụng');
        });
    });

    describe('POST /api/auth/login', () => {
        test('Đăng nhập thành công', async () => {
            const mockComparePassword = jest.fn().mockResolvedValue(true);
            const mockUser = {
                _id: '6523e12089b25c3decfb3f9b',
                email: 'test@example.com',
                phone: '0987654321',
                comparePassword: mockComparePassword
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    emailOrPhone: 'test@example.com',
                    password: 'password123'
                });

            expect(res.status).toBe(200);
            expect(res.body.message).toContain('Đăng nhập thành công');
            expect(res.body).toHaveProperty('token');
            expect(res.body.user.email).toBe('test@example.com');
        });

        test('Thất bại khi tài khoản không tồn tại', async () => {
            User.findOne = jest.fn().mockResolvedValue(null);

            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    emailOrPhone: 'nonexistent@example.com',
                    password: 'password123'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('Tài khoản không tồn tại');
        });

        test('Thất bại khi sai mật khẩu', async () => {
            const mockComparePassword = jest.fn().mockResolvedValue(false);
            const mockUser = {
                _id: '6523e12089b25c3decfb3f9b',
                email: 'test@example.com',
                comparePassword: mockComparePassword
            };

            User.findOne = jest.fn().mockResolvedValue(mockUser);

            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    emailOrPhone: 'test@example.com',
                    password: 'wrongpassword'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('Mật khẩu không chính xác');
        });
    });
});
