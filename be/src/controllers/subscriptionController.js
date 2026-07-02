const Subscription = require('../models/Subscription');

const toSubscriptionResponse = (subscription) => {
    const now = new Date();
    const isActive = subscription?.status === 'active' &&
        subscription.endDate &&
        new Date(subscription.endDate) > now;

    return {
        plan: isActive ? subscription.plan : 'free',
        status: isActive ? 'active' : 'free',
        isPro: Boolean(isActive),
        startDate: isActive ? subscription.startDate : null,
        endDate: isActive ? subscription.endDate : null,
        provider: subscription?.provider || null
    };
};

exports.toSubscriptionResponse = toSubscriptionResponse;

exports.getMySubscription = async (req, res) => {
    try {
        const subscription = await Subscription.findOne({ user: req.user.id });
        if (!subscription) {
            return res.status(200).json(toSubscriptionResponse(null));
        }

        if (subscription.status === 'active' &&
            subscription.endDate &&
            new Date(subscription.endDate) <= new Date()) {
            subscription.status = 'expired';
            await subscription.save();
        }

        res.status(200).json(toSubscriptionResponse(subscription));
    } catch (error) {
        console.error('Error in subscriptionController.getMySubscription:', error);
        res.status(500).json({ error: error.message });
    }
};
