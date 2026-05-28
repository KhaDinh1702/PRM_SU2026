const express = require('express');
const router = express.Router();
const projectController = require('../controllers/projectController');
const auth = require('../middleware/auth');

router.get('/', auth, projectController.getProjects);
router.post('/', auth, projectController.createProject);
router.get('/:projectId', auth, projectController.getProjectById);
router.put('/:projectId', auth, projectController.updateProject);
router.delete('/:projectId', auth, projectController.deleteProject);
router.post('/:projectId/members', auth, projectController.addMember);
router.get('/:projectId/tasks', auth, projectController.getProjectTasks);

module.exports = router;
