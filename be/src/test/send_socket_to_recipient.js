const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const ioClient = require('socket.io-client');
const Project = require('../models/Project');

(async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const project = await Project.findOne().lean();
        if (!project) {
            console.error('No project found');
            process.exit(1);
        }

        const projectId = project._id.toString();
        const recipientId = project.members && project.members.length ? project.members[0].toString() : (project.owner ? project.owner.toString() : null);
        const senderId = project.owner ? project.owner.toString() : (project.members && project.members[0] ? project.members[0].toString() : null);

        if (!recipientId || !senderId) {
            console.error('Missing recipient/sender');
            process.exit(1);
        }

        console.log('Project:', projectId, 'recipient:', recipientId, 'sender:', senderId);

        const socket = ioClient(process.env.SOCKET_URL || `http://localhost:${process.env.PORT || 5000}`);

        socket.on('connect', () => {
            console.log('Client connected', socket.id);
            socket.emit('joinUser', recipientId);

            setTimeout(() => {
                socket.emit('sendMessage', { projectId, senderId, text: 'Automated notification test to recipient' });
                console.log('sendMessage emitted');
            }, 300);
        });

        socket.on('userNotification', (notif) => {
            console.log('Received userNotification:', notif);
            socket.close();
            process.exit(0);
        });

        socket.on('userNotificationPlain', (notif) => {
            console.log('Received userNotificationPlain:', notif);
            socket.close();
            process.exit(0);
        });

        socket.on('connect_error', (err) => {
            console.error('Connect error:', err);
            process.exit(1);
        });

        setTimeout(() => {
            console.log('Timeout waiting for notification; exiting');
            socket.close();
            process.exit(0);
        }, 8000);

    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
})();
