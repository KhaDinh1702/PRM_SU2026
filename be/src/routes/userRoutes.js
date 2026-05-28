const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: User Profile
 *   description: Quản lý hồ sơ và các cài đặt cá nhân của người dùng
 */

/**
 * @swagger
 * /api/users/profile:
 *   get:
 *     summary: Lấy thông tin cá nhân và cài đặt của người dùng hiện tại
 *     tags: [User Profile]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Trả về chi tiết hồ sơ cá nhân và settings của user
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 *       404:
 *         description: Không tìm thấy người dùng
 */
router.get('/profile', auth, userController.getProfile);

/**
 * @swagger
 * /api/user/profile:
 *   put:
 *     summary: Cập nhật thông tin cá nhân hoặc các cài đặt Pomodoro/Theme của người dùng
 *     tags: [User Profile]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Dinh Hoang Kha (Updated)"
 *               phone:
 *                 type: string
 *                 example: "0987654322"
 *               bio:
 *                 type: string
 *                 example: "Đam mê lập trình và quản lý thời gian."
 *               avatarUrl:
 *                 type: string
 *                 example: "https://avatar.url/me.jpg"
 *               settings:
 *                 type: object
 *                 properties:
 *                   theme:
 *                     type: string
 *                     example: "light"
 *                   focusTime:
 *                     type: number
 *                     example: 30
 *                   shortBreak:
 *                     type: number
 *                     example: 5
 *                   longBreak:
 *                     type: number
 *                     example: 20
 *     responses:
 *       200:
 *         description: Cập nhật thông tin hồ sơ cá nhân thành công
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 */
router.put('/profile', auth, userController.updateProfile);

module.exports = router;
