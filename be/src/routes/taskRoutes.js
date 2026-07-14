const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const auth = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Tasks
 *   description: Quản lý công việc cá nhân hoặc thuộc dự án (CRUD)
 */

/**
 * @swagger
 * /api/tasks:
 *   get:
 *     summary: Lấy danh sách công việc của người dùng
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [Pending, In Progress, Review, Completed, Overdue]
 *         description: Lọc theo trạng thái
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [Low, Medium, High]
 *         description: Lọc theo độ ưu tiên
 *       - in: query
 *         name: project
 *         schema:
 *           type: string
 *         description: Lọc theo ID project (hoặc truyền 'null' để lọc task cá nhân không thuộc project)
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Tìm kiếm task theo tên (không phân biệt chữ hoa/thường)
 *     responses:
 *       200:
 *         description: Trả về danh sách công việc lọc theo query
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 */
router.get('/', auth, taskController.getTasks);

/**
 * @swagger
 * /api/tasks:
 *   post:
 *     summary: Tạo một công việc mới
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Học lập trình Flutter nâng cao"
 *               description:
 *                 type: string
 *                 example: "Học các khái niệm Bloc, Provider và State Management"
 *               status:
 *                 type: string
 *                 enum: [Pending, In Progress, Review, Completed, Overdue]
 *                 example: "Pending"
 *               priority:
 *                 type: string
 *                 enum: [Low, Medium, High]
 *                 example: "Medium"
 *               deadline:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-06-01T17:00:00.000Z"
 *               label:
 *                 type: string
 *                 example: "Study"
 *               project:
 *                 type: string
 *                 example: null
 *     responses:
 *       201:
 *         description: Tạo công việc thành công
 *       400:
 *         description: Thiếu tiêu đề công việc hoặc dữ liệu không hợp lệ
 */
router.post('/', auth, taskController.createTask);

/**
 * @swagger
 * /api/tasks/{taskId}:
 *   put:
 *     summary: Chỉnh sửa hoặc cập nhật trạng thái/thông tin công việc
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID của task cần sửa
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [Pending, In Progress, Review, Completed, Overdue]
 *               priority:
 *                 type: string
 *                 enum: [Low, Medium, High]
 *               deadline:
 *                 type: string
 *                 format: date-time
 *               label:
 *                 type: string
 *               project:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật công việc thành công
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 *       404:
 *         description: Công việc không tồn tại hoặc không có quyền sửa
 */
router.put('/:taskId', auth, taskController.updateTask);

/**
 * @swagger
 * /api/tasks/{taskId}:
 *   delete:
 *     summary: Xóa một công việc
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID của task cần xóa
 *     responses:
 *       200:
 *         description: Xóa công việc thành công
 *       401:
 *         description: Chưa đăng nhập hoặc token không hợp lệ
 *       404:
 *         description: Công việc không tồn tại hoặc không có quyền xóa
 */
router.delete('/:taskId', auth, taskController.deleteTask);

module.exports = router;
