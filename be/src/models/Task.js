const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        trim: true,
        default: ''
    },
    status: {
        type: String,
        enum: ['Pending', 'In Progress', 'Completed', 'Overdue'],
        default: 'Pending'
    },
    priority: {
        type: String,
        enum: ['Low', 'Medium', 'High', 'Urgent'],
        default: 'Medium'
    },
    deadline: {
        type: Date
    },
    label: {
        type: String,
        trim: true,
        default: ''
    },
    sourceType: {
        type: String,
        enum: ['personal', 'project', 'schedule'],
        default: 'personal'
    },
    project: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Project',
        default: null
    },
    scheduleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Event',
        default: null
    },
    assignedTo: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    assignedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    startDate: {
        type: Date
    },
    dueDate: {
        type: Date
    },
    dueTime: {
        type: String,
        trim: true,
        default: ''
    },
    reminderType: {
        type: String,
        enum: ['none', 'at_time', '15_min_before', '30_min_before', '1_hour_before', '1_day_before', 'custom'],
        default: 'none'
    },
    reminderOffset: {
        type: Number,
        default: null
    },
    notificationEnabled: {
        type: Boolean,
        default: false
    },
    location: {
        placeName: {
            type: String,
            trim: true,
            default: ''
        },
        address: {
            type: String,
            trim: true,
            default: ''
        },
        latitude: {
            type: Number,
            default: null
        },
        longitude: {
            type: Number,
            default: null
        },
        reminderRadiusMeters: {
            type: Number,
            default: 100
        }
    },
    completedAt: {
        type: Date
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }
}, {
    timestamps: true
});

taskSchema.index({ project: 1, status: 1 });
taskSchema.index({ user: 1, status: 1, createdAt: -1 });
taskSchema.index({ user: 1, deadline: 1, status: 1 });
taskSchema.index({ project: 1, assignedTo: 1, status: 1 });
taskSchema.index({ assignedTo: 1, deadline: 1, status: 1 });
taskSchema.index({ createdBy: 1, deadline: 1, status: 1 });
taskSchema.index({ sourceType: 1, deadline: 1 });
taskSchema.index({ user: 1, 'location.latitude': 1, 'location.longitude': 1 });

module.exports = mongoose.model('Task', taskSchema);
