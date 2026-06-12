/**
 * Cập nhật các trường dữ liệu của Task dựa trên quyền chỉnh sửa.
 * @param {Object} task - Mongoose document đại diện cho Task cần sửa
 * @param {Object} updates - Các trường cần cập nhật gửi từ request body
 * @param {Boolean} canEditFields - Quyền hạn chỉnh sửa đầy đủ (Owner, Manager, hoặc Creator)
 * @returns {Object} task document sau khi cập nhật các trường
 */
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
        notificationEnabled
    } = updates;

    // Bất kỳ ai được gán task hoặc có quyền chỉnh sửa đều được cập nhật status
    if (status !== undefined) {
        task.status = status;
        task.completedAt = status === 'Completed' ? new Date() : null;
    }

    // Các trường chi tiết khác chỉ được sửa nếu có quyền canEditFields
    if (canEditFields) {
        if (title !== undefined) task.title = title;
        if (description !== undefined) task.description = description;
        if (priority !== undefined) task.priority = priority;
        
        // Đồng bộ deadline và dueDate
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
        if (assignedTo !== undefined) {
            task.assignedTo = assignedTo;
            task.user = assignedTo; // Trường user giữ để map logic cá nhân hóa ở schema
        }
    }
    return task;
};

module.exports = {
    updateTaskFields
};
