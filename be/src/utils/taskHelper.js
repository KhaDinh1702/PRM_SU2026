const normalizeTaskLocation = (location) => {
    if (!location || typeof location !== 'object') {
        return {
            placeName: '',
            address: '',
            latitude: null,
            longitude: null,
            reminderRadiusMeters: 100
        };
    }

    const latitude = Number(location.latitude);
    const longitude = Number(location.longitude);
    const reminderRadiusMeters = Number(location.reminderRadiusMeters);

    return {
        placeName: location.placeName ? String(location.placeName).trim() : '',
        address: location.address ? String(location.address).trim() : '',
        latitude: Number.isFinite(latitude) ? latitude : null,
        longitude: Number.isFinite(longitude) ? longitude : null,
        reminderRadiusMeters: Number.isFinite(reminderRadiusMeters)
            ? Math.max(25, Math.round(reminderRadiusMeters))
            : 100
    };
};

const updateTaskFields = (task, updates, canEditFields) => {
    const {
        title,
        description,
        status,
        priority,
        deadline,
        label,
        assignedTo,
        startDate,
        dueDate,
        dueTime,
        reminderType,
        reminderOffset,
        notificationEnabled,
        location
    } = updates;

    if (status !== undefined) {
        task.status = status;
        task.completedAt = status === 'Completed' ? new Date() : null;
    }

    if (canEditFields) {
        if (title !== undefined) task.title = title;
        if (description !== undefined) task.description = description;
        if (priority !== undefined) task.priority = priority;

        if (deadline !== undefined) {
            task.deadline = deadline;
            task.dueDate = deadline;
        }
        if (dueDate !== undefined) {
            task.dueDate = dueDate;
            task.deadline = dueDate;
        }

        if (startDate !== undefined) task.startDate = startDate;
        if (dueTime !== undefined) task.dueTime = dueTime;
        if (reminderType !== undefined) task.reminderType = reminderType || 'none';
        if (reminderOffset !== undefined) task.reminderOffset = reminderOffset;
        if (notificationEnabled !== undefined) {
            task.notificationEnabled = Boolean(notificationEnabled && task.reminderType !== 'none');
        }
        if (label !== undefined) task.label = label;
        if (location !== undefined) task.location = normalizeTaskLocation(location);
        if (assignedTo !== undefined) {
            task.assignedTo = assignedTo;
            task.user = assignedTo;
        }
    }
    return task;
};

module.exports = {
    updateTaskFields,
    normalizeTaskLocation
};
