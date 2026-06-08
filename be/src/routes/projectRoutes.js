const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const auth = require('../middleware/auth');

router.get('/', auth, projectController.getProjects);
router.post('/', auth, projectController.createProject);
router.post('/:projectId/members', auth, projectController.addMember);
router.put('/:projectId/members/:userId/role', auth, projectController.updateMemberRole);
router.post('/:projectId/invitations/:notificationId/respond', auth, projectController.respondToInvitation);
router.get('/:projectId/tasks', auth, projectController.getProjectTasks);
router.post('/:projectId/tasks', auth, projectController.createProjectTask);
router.put('/:projectId/tasks/:taskId', auth, projectController.updateProjectTask);
router.get('/:projectId', auth, projectController.getProjectById);
router.put('/:projectId', auth, projectController.updateProject);
router.delete('/:projectId', auth, projectController.deleteProject);

module.exports = router;
