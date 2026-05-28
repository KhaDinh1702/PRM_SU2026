const request = require('supertest');
const express = require('express');
const taskRoutes = require('../src/routes/taskRoutes');
const Task = require('../src/models/Task');

const app = express();
app.use(express.json());
app.use('/api/tasks', taskRoutes);

// Mock auth middleware
jest.mock('../src/middleware/auth', () => (req, res, next) => {
    req.user = { id: '6523e12089b25c3decfb3f9b' };
    next();
});

jest.mock('../src/models/Task', () => {
    const mockConstructor = function (data) {
        this._id = '6523e12089b25c3decfb3f9c';
        this.title = data?.title;
        this.description = data?.description;
        this.status = data?.status || 'Pending';
        this.priority = data?.priority || 'Medium';
        this.user = '6523e12089b25c3decfb3f9b';
        this.save = jest.fn().mockResolvedValue(this);
    };
    mockConstructor.find = jest.fn().mockReturnValue({
        populate: jest.fn().mockReturnValue({
            sort: jest.fn().mockResolvedValue([])
        })
    });
    mockConstructor.findOne = jest.fn();
    mockConstructor.findOneAndDelete = jest.fn();
    return mockConstructor;
});

describe('Task API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('GET /api/tasks - Lấy danh sách task thành công', async () => {
        const res = await request(app).get('/api/tasks');
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
    });

    test('POST /api/tasks - Tạo task mới thành công', async () => {
        const res = await request(app)
            .post('/api/tasks')
            .send({
                title: 'Học Flutter',
                description: 'Học lập trình di động'
            });

        expect(res.status).toBe(201);
        expect(res.body.title).toBe('Học Flutter');
    });

    test('POST /api/tasks - Thất bại khi thiếu title', async () => {
        const res = await request(app)
            .post('/api/tasks')
            .send({
                description: 'Thiếu title'
            });

        expect(res.status).toBe(400);
        expect(res.body.error).toContain('Tiêu đề công việc là bắt buộc');
    });
});
