require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');

// Import Routers
const authRoutes = require('./routes/authRoutes');
const sessionRoutes = require('./routes/sessionRoutes');
const userRoutes = require('./routes/userRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const taskRoutes = require('./routes/taskRoutes');
const projectRoutes = require('./routes/projectRoutes');
const calendarRoutes = require('./routes/calendarRoutes');
const focusRoutes = require('./routes/focusRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Connect to Database
connectDB();

// Swagger UI với Custom Premium Cyber Dark Theme CSS
const swaggerCustomOptions = {
    customCss: `
        .swagger-ui { background-color: #0b0f19; color: #e2e8f0; font-family: 'Outfit', sans-serif; }
        .swagger-ui .info .title { color: #f8fafc; font-weight: 800; font-size: 32px; letter-spacing: -0.5px; }
        .swagger-ui .info p, .swagger-ui .info li, .swagger-ui .info td { color: #94a3b8; }
        .swagger-ui .scheme-container { background-color: #111827; border: 1px solid #1f2937; border-radius: 16px; margin: 20px 0; box-shadow: 0 4px 20px rgba(0,0,0,0.25); }
        .swagger-ui .opblock { border-radius: 12px; border: none; box-shadow: 0 4px 12px rgba(0,0,0,0.15); overflow: hidden; margin-bottom: 12px; }
        .swagger-ui .opblock .opblock-summary { padding: 12px 20px; background-color: #111827; }
        .swagger-ui .opblock-tag { border-bottom: 1px solid #1f2937; color: #cbd5e1; font-size: 18px; font-weight: bold; }
        .swagger-ui .btn.authorize { background-color: #8b5cf6; border-color: #8b5cf6; color: #fff; border-radius: 8px; font-weight: bold; transition: all 0.2s; }
        .swagger-ui .btn.authorize:hover { background-color: #7c3aed; border-color: #7c3aed; }
        .swagger-ui .btn.authorize svg { fill: #fff; }
        .swagger-ui .opblock.opblock-post { background-color: #061c15; border: 1px solid #064e3b; }
        .swagger-ui .opblock.opblock-get { background-color: #071e30; border: 1px solid #0c4a6e; }
        .swagger-ui .opblock.opblock-put { background-color: #241a06; border: 1px solid #78350f; }
        .swagger-ui .opblock.opblock-delete { background-color: #240c0c; border: 1px solid #7f1d1d; }
        .swagger-ui select, .swagger-ui input[type=text] { background-color: #1e293b; color: #f8fafc; border: 1px solid #334155; border-radius: 6px; }
        .swagger-ui .dialog-ux .modal-ux { background-color: #111827; border: 1px solid #1f2937; border-radius: 20px; }
        .swagger-ui .dialog-ux .modal-ux-header h3 { color: #f8fafc; }
        .swagger-ui .dialog-ux .modal-ux-content p { color: #94a3b8; }
    `,
    customSiteTitle: "FlowMate API Documents 🚀"
};

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, swaggerCustomOptions));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/users', userRoutes);
app.use('/api/user', userRoutes); // Phục vụ cả PUT /api/user/profile
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/calendar', calendarRoutes);
app.use('/api/focus-sessions', focusRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', analyticsRoutes);

// Basic Route
app.get('/api/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        message: 'Backend is running smoothly',
        timestamp: new Date().toISOString()
    });
});

const PORT = process.env.PORT || 5000;

if (process.env.NODE_ENV !== 'test') {
    app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT}`);
    });
}

module.exports = app;
