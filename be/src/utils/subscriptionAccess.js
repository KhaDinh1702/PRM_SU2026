const Subscription = require('../models/Subscription');

const FREE_LIMITS = {
    personalTasks: Number(process.env.FREE_PERSONAL_TASK_LIMIT) || 20,
    projects: Number(process.env.FREE_PROJECT_LIMIT) || 3
};

const isSubscriptionActive = (subscription) => {
    return subscription?.status === 'active' &&
        subscription.endDate &&
        new Date(subscription.endDate) > new Date();
};

const getSubscriptionAccess = async (userId) => {
    const subscription = await Subscription.findOne({ user: userId }).lean();
    const isPro = isSubscriptionActive(subscription);
    return {
        isPro,
        plan: isPro ? subscription.plan : 'free',
        limits: FREE_LIMITS
    };
};

const hasLocationPayload = (location) => {
    if (!location || typeof location !== 'object') return false;
    const hasText = Boolean(location.placeName?.toString().trim()) ||
        Boolean(location.address?.toString().trim());
    const hasLatitude = location.latitude !== undefined &&
        location.latitude !== null &&
        Number.isFinite(Number(location.latitude));
    const hasLongitude = location.longitude !== undefined &&
        location.longitude !== null &&
        Number.isFinite(Number(location.longitude));
    return hasText || (hasLatitude && hasLongitude);
};

const requirePro = async (userId, feature, message) => {
    const access = await getSubscriptionAccess(userId);
    if (!access.isPro) {
        const error = new Error(message);
        error.status = 402;
        error.code = 'PRO_REQUIRED';
        error.feature = feature;
        throw error;
    }
    return access;
};

module.exports = {
    FREE_LIMITS,
    getSubscriptionAccess,
    hasLocationPayload,
    requirePro
};
