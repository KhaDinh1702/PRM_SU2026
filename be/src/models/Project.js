const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true,
        default: ''
    },
    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    members: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    memberRoles: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        role: {
            type: String,
            enum: ['Manager', 'Member'],
            default: 'Member'
        }
    }],
    deadline: {
        type: Date
    },
    status: {
        type: String,
        enum: ['Active', 'Completed', 'On Hold'],
        default: 'Active'
    },
    type: {
        type: String,
        enum: ['Personal', 'Team', 'Study', 'Work'],
        default: 'Personal'
    },
    allowMembersToCreateTasks: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

projectSchema.index({ owner: 1, createdAt: -1 });
projectSchema.index({ members: 1, createdAt: -1 });
projectSchema.index({ 'memberRoles.user': 1 });

module.exports = mongoose.model('Project', projectSchema);
