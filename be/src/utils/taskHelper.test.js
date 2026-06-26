const { updateTaskFields } = require('./taskHelper');

describe('taskHelper - updateTaskFields', () => {
    let mockTask;

    beforeEach(() => {
        mockTask = {
            title: 'Task cũ',
            description: 'Mô tả cũ',
            status: 'Pending',
            priority: 'Medium',
            deadline: null,
            dueDate: null,
            startDate: null,
            dueTime: '',
            reminderType: 'none',
            reminderOffset: null,
            notificationEnabled: false,
            label: '',
            location: null,
            assignedTo: null,
            user: null
        };
    });

    test('Nên cập nhật status và completedAt cho bất kỳ ai', () => {
        const updates = { status: 'Completed' };
        const updated = updateTaskFields(mockTask, updates, false);
        
        expect(updated.status).toBe('Completed');
        expect(updated.completedAt).toBeInstanceOf(Date);
    });

    test('Không được cập nhật các trường chi tiết nếu canEditFields = false', () => {
        const updates = {
            title: 'Task mới',
            description: 'Mô tả mới',
            priority: 'High'
        };
        const updated = updateTaskFields(mockTask, updates, false);
        
        expect(updated.title).toBe('Task cũ');
        expect(updated.description).toBe('Mô tả cũ');
        expect(updated.priority).toBe('Medium');
    });

    test('Cập nhật đầy đủ chi tiết và đồng bộ deadline/dueDate nếu canEditFields = true', () => {
        const testDate = new Date('2026-07-01T12:00:00.000Z');
        const updates = {
            title: 'Task mới',
            description: 'Mô tả mới',
            priority: 'High',
            deadline: testDate,
            reminderType: 'at_time',
            notificationEnabled: true
        };
        const updated = updateTaskFields(mockTask, updates, true);
        
        expect(updated.title).toBe('Task mới');
        expect(updated.description).toBe('Mô tả mới');
        expect(updated.priority).toBe('High');
        expect(updated.deadline).toEqual(testDate);
        expect(updated.dueDate).toEqual(testDate);
        expect(updated.reminderType).toBe('at_time');
        expect(updated.notificationEnabled).toBe(true);
    });

    test('Cap nhat location neu canEditFields = true', () => {
        const updated = updateTaskFields(mockTask, {
            location: {
                placeName: 'Thu vien',
                address: 'Nguyen Trai',
                latitude: '10.762622',
                longitude: '106.660172',
                reminderRadiusMeters: '150'
            }
        }, true);

        expect(updated.location).toEqual({
            placeName: 'Thu vien',
            address: 'Nguyen Trai',
            latitude: 10.762622,
            longitude: 106.660172,
            reminderRadiusMeters: 150
        });
    });
});
