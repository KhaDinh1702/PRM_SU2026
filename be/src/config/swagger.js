const swaggerJSDoc = require('swagger-jsdoc');

const swaggerSpec = swaggerJSDoc({
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Space Timer API',
            version: '1.0.0',
            description: 'Tài liệu hướng dẫn sử dụng API Space Timer (Pomodoro, Tasks, Projects, Calendar, Analytics).',
        },
        servers: [
            {
                url: 'https://prm-tan.vercel.app',
                description: 'Production'
            }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT',
                    description: 'Nhập JWT Token của ông chủ vào đây.'
                }
            }
        },
        security: [{ bearerAuth: [] }]
    },
    apis: ['./src/routes/*.js']
});

module.exports = swaggerSpec;
