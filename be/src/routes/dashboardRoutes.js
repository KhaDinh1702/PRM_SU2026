const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const auth = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Dashboard
 *   description: API tổng hợp thông tin hiển thị màn hình Dashboard
 */

/**
 * @swagger
 * /api/dashboard/summary:
 *   get:
 *     summary: Lấy dữ liệu tổng quan cho màn hình Dashboard
 *     tags: [Dashboard]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về số lượng task cần làm, task đã hoàn thành, lịch họp gần nhất, project đang tham gia và tổng thời gian focus trong ngày
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 */
router.get('/summary', auth, dashboardController.getSummary);

module.exports = router;
