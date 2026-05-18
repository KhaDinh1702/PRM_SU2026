const request = require('supertest');
const express = require('express');
const sessionRoutes = require('../src/routes/sessionRoutes');
const Session = require('../src/models/Session');

const app = express();
app.use(express.json());
app.use('/api/sessions', sessionRoutes);

// Mock Session operations to keep tests isolated from real MongoDB during unit testing
jest.mock('../src/models/Session');

describe('Sessions API Endpoints', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('POST /api/sessions - success', async () => {
        const mockSession = {
            mode: 'Focus',
            durationSeconds: 1500,
            completedAt: new Date().toISOString()
        };

        // Mock model instantiation and save
        Session.prototype.save = jest.fn().mockResolvedValue(mockSession);

        const res = await request(app)
            .post('/api/sessions')
            .send({ mode: 'Focus', durationSeconds: 1500 });

        expect(res.status).toBe(201);
        expect(res.body.mode).toBe('Focus');
        expect(res.body.durationSeconds).toBe(1500);
    });

    test('POST /api/sessions - validation error missing fields', async () => {
        const res = await request(app)
            .post('/api/sessions')
            .send({ mode: 'Focus' });

        expect(res.status).toBe(400);
        expect(res.body.error).toContain('Missing required fields');
    });

    test('GET /api/sessions - get history success', async () => {
        const mockSessions = [
            { mode: 'Focus', durationSeconds: 1500 },
            { mode: 'Short Break', durationSeconds: 300 }
        ];

        Session.find = jest.fn().mockReturnValue({
            sort: jest.fn().mockReturnValue({
                limit: jest.fn().mockResolvedValue(mockSessions)
            })
        });

        const res = await request(app).get('/api/sessions');
        expect(res.status).toBe(200);
        expect(res.body.length).toBe(2);
        expect(res.body[0].mode).toBe('Focus');
    });

    test('GET /api/sessions/stats - get aggregate stats success', async () => {
        const mockAggregateResult = [
            { _id: 'Focus', count: 2, totalSeconds: 3000 },
            { _id: 'Short Break', count: 1, totalSeconds: 300 }
        ];

        Session.aggregate = jest.fn().mockResolvedValue(mockAggregateResult);

        const res = await request(app).get('/api/sessions/stats');
        expect(res.status).toBe(200);
        expect(res.body.totalSessions).toBe(3);
        expect(res.body.totalFocusMinutes).toBe(50); // 3000 / 60
        expect(res.body.totalBreakMinutes).toBe(5);   // 300 / 60
    });
});
