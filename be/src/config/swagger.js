const swaggerJSDoc = require('swagger-jsdoc');
const path = require('path');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Space Timer & Productivity API Documentation',
            version: '1.0.0',
            description: 'Tài liệu hướng dẫn sử dụng toàn bộ API của ứng dụng quản lý năng suất Space Timer (Pomodoro, Tasks, Projects, Calendar, Analytics).',
            contact: {
                name: 'Antigravity Developer',
            },
        },
        servers: [
            {
                url: 'https://prm-tan.vercel.app',
                description: 'Production Cloud Server'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Nhập JWT Token của ông chủ vào đây theo cú pháp: <Token>'
                }
            }
        },
        security: [
            {
                bearerAuth: []
            }
        ]
    },
    apis: [path.join(__dirname, '../routes/*.js')] // Quét JSDoc định nghĩa bằng đường dẫn tuyệt đối
};

const swaggerSpec = swaggerJSDoc(options);

module.exports = swaggerSpec;
