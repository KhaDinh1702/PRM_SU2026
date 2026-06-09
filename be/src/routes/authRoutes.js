const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

/**
 * @swagger
 * tags:
 *   name: Authentication
 *   description: Quản lý đăng ký, đăng nhập và xác thực tài khoản
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Đăng ký tài khoản mới
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Dinh Hoang Kha"
 *               email:
 *                 type: string
 *                 example: "dinhhoangkha107@example.com"
 *               phone:
 *                 type: string
 *                 example: "0987654321"
 *               password:
 *                 type: string
 *                 example: "password123"
 *     responses:
 *       201:
 *         description: Đăng ký tài khoản thành công
 *       400:
 *         description: Email đã được sử dụng hoặc thông tin đầu vào không hợp lệ
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/auth/send-otp:
 *   post:
 *     summary: Gửi mã OTP qua Email
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 example: "nguyenbao2004vn@gmail.com"
 *     responses:
 *       200:
 *         description: Mã OTP đã được gửi thành công
 *       400:
 *         description: Thiếu email hoặc email đã đăng ký
 */
router.post('/send-otp', authController.sendOtp);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Đăng nhập tài khoản
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - emailOrPhone
 *               - password
 *             properties:
 *               emailOrPhone:
 *                 type: string
 *                 example: "dinhhoangkha107@example.com"
 *               password:
 *                 type: string
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Đăng nhập thành công và trả về JWT Token
 *       400:
 *         description: Tài khoản không tồn tại hoặc sai mật khẩu
 */
router.post('/login', authController.login);

module.exports = router;
