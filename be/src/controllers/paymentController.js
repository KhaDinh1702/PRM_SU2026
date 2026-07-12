const { PayOS } = require('@payos/node');
const Payment = require('../models/Payment');
const Subscription = require('../models/Subscription');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { toSubscriptionResponse } = require('./subscriptionController');

const planAmount = (envName, fallback) => {
    const amount = Number(process.env[envName]);
    return Number.isFinite(amount) && amount > 0 ? amount : fallback;
};

const PLANS = {
    pro_monthly: {
        id: 'pro_monthly',
        name: 'FlowMate Pro Monthly',
        label: 'Pro Monthly',
        amount: planAmount('PAYOS_PRO_MONTHLY_AMOUNT', 5000),
        durationDays: 30
    },
    pro_yearly: {
        id: 'pro_yearly',
        name: 'FlowMate Pro Yearly',
        label: 'Pro Yearly',
        amount: planAmount('PAYOS_PRO_YEARLY_AMOUNT', 199000),
        durationDays: 365
    }
};

let payosClient;

const getPayOS = () => {
    if (payosClient) return payosClient;
    const clientId = process.env.PAYOS_CLIENT_ID;
    const apiKey = process.env.PAYOS_API_KEY;
    const checksumKey = process.env.PAYOS_CHECKSUM_KEY;

    if (!clientId || !apiKey || !checksumKey) {
        const error = new Error('PayOS is not configured. Please set PAYOS_CLIENT_ID, PAYOS_API_KEY, and PAYOS_CHECKSUM_KEY on the backend.');
        error.status = 500;
        throw error;
    }

    payosClient = new PayOS({
        clientId,
        apiKey,
        checksumKey,
        logLevel: process.env.PAYOS_LOG_LEVEL || 'warn'
    });
    return payosClient;
};

const generateOrderCode = () => {
    const suffix = Math.floor(Math.random() * 90) + 10;
    return Number(`${Date.now()}${suffix}`);
};

const appendOrderCode = (url, orderCode) => {
    if (url.includes('{orderCode}')) return url.replace('{orderCode}', orderCode.toString());
    try {
        const parsed = new URL(url);
        parsed.searchParams.set('orderCode', orderCode.toString());
        return parsed.toString();
    } catch (_) {
        return url;
    }
};

const getReturnUrl = (orderCode) => {
    const appUrl = process.env.PAYOS_PUBLIC_APP_URL || process.env.FRONTEND_URL || 'https://prm-tan.vercel.app';
    return appendOrderCode(process.env.PAYOS_RETURN_URL || `${appUrl}/payment/success`, orderCode);
};

const getCancelUrl = (orderCode) => {
    const appUrl = process.env.PAYOS_PUBLIC_APP_URL || process.env.FRONTEND_URL || 'https://prm-tan.vercel.app';
    return appendOrderCode(process.env.PAYOS_CANCEL_URL || `${appUrl}/payment/cancel`, orderCode);
};

const createSubscriptionNotification = async (payment, subscription, io) => {
    const plan = PLANS[payment.plan];
    if (!plan || !subscription) return null;

    let notification;
    try {
        notification = await Notification.create({
            title: 'FlowMate Pro activated',
            message: `Your payment of ${payment.amount.toLocaleString('vi-VN')} VND was confirmed. ${plan.label} is now active.`,
            type: 'system',
            user: payment.user,
            dedupeKey: `subscription-payment:${payment._id}`
        });
    } catch (error) {
        if (error?.code === 11000) {
            return Notification.findOne({
                dedupeKey: `subscription-payment:${payment._id}`
            });
        }
        console.warn('Could not create subscription notification:', error.message);
        return null;
    }

    if (io && notification) {
        io.to(`user:${payment.user.toString()}`).emit('userNotification', notification);
        io.to(`user:${payment.user.toString()}`).emit('userNotificationPlain', {
            id: notification._id?.toString(),
            user: payment.user.toString(),
            title: notification.title,
            message: notification.message
        });
    }

    return notification;
};

const createUnpaidNotification = async (payment, status, io) => {
    const content = {
        cancelled: {
            title: 'Payment cancelled',
            message: 'Your PayOS payment was cancelled. Your current plan was not changed.'
        },
        expired: {
            title: 'Payment link expired',
            message: 'Your PayOS payment link expired after 15 minutes. No charge was made.'
        },
        failed: {
            title: 'Payment failed',
            message: 'Your PayOS payment could not be completed. Your current plan was not changed.'
        },
        abandoned: {
            title: 'Payment not completed',
            message: 'You closed PayOS before completing payment. The payment link expires after 15 minutes.'
        }
    }[status];
    if (!content) return null;

    let notification;
    try {
        notification = await Notification.create({
            ...content,
            type: 'system',
            user: payment.user,
            dedupeKey: `unpaid-payment:${payment._id}`
        });
    } catch (error) {
        if (error?.code === 11000) {
            return Notification.findOne({
                dedupeKey: `unpaid-payment:${payment._id}`
            });
        }
        console.warn('Could not create unpaid payment notification:', error.message);
        return null;
    }

    if (io && notification) {
        io.to(`user:${payment.user.toString()}`).emit('userNotification', notification);
        io.to(`user:${payment.user.toString()}`).emit('userNotificationPlain', {
            id: notification._id?.toString(),
            user: payment.user.toString(),
            title: notification.title,
            message: notification.message
        });
    }

    return notification;
};

const activateSubscription = async (payment, io) => {
    const plan = PLANS[payment.plan];
    if (!plan) return null;

    const now = new Date();
    const current = await Subscription.findOne({ user: payment.user });
    if (current?.latestPayment?.toString() === payment._id.toString()) {
        await createSubscriptionNotification(payment, current, io);
        return current;
    }

    const baseDate = current?.status === 'active' &&
        current.endDate &&
        new Date(current.endDate) > now
        ? new Date(current.endDate)
        : now;
    const endDate = new Date(baseDate);
    endDate.setDate(endDate.getDate() + plan.durationDays);

    const subscription = await Subscription.findOneAndUpdate(
        { user: payment.user },
        {
            $set: {
                plan: payment.plan,
                status: 'active',
                startDate: current?.startDate || now,
                endDate,
                latestPayment: payment._id,
                provider: 'payos'
            }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await createSubscriptionNotification(payment, subscription, io);
    return subscription;
};

const mapProviderStatus = (status) => {
    switch ((status || '').toUpperCase()) {
        case 'PAID':
            return 'paid';
        case 'CANCELLED':
            return 'cancelled';
        case 'EXPIRED':
            return 'expired';
        case 'FAILED':
            return 'failed';
        default:
            return 'pending';
    }
};

const syncPaymentFromPayOS = async (payment, io) => {
    if (!payment || payment.status !== 'pending') return payment;
    const payos = getPayOS();
    const providerPayment = await payos.paymentRequests.get(payment.orderCode);
    const nextStatus = mapProviderStatus(providerPayment.status);

    payment.providerStatus = providerPayment.status || '';
    payment.rawPayload = providerPayment;
    payment.status = nextStatus;
    if (nextStatus === 'paid' && !payment.paidAt) payment.paidAt = new Date();
    await payment.save();

    if (nextStatus === 'paid') {
        await activateSubscription(payment, io);
    } else if (['cancelled', 'expired', 'failed'].includes(nextStatus)) {
        await createUnpaidNotification(payment, nextStatus, io);
    }

    return payment;
};

exports.createPayOSPaymentLink = async (req, res) => {
    try {
        const planId = req.body.plan || req.body.planId;
        const plan = PLANS[planId];
        if (!plan) {
            return res.status(400).json({ error: 'Invalid subscription plan.' });
        }

        const payos = getPayOS();
        const user = await User.findById(req.user.id).select('email name phone');
        if (!user) return res.status(404).json({ error: 'User not found.' });

        const orderCode = generateOrderCode();
        const payment = await Payment.create({
            user: user._id,
            plan: plan.id,
            orderCode,
            amount: plan.amount,
            description: 'FlowMate Pro',
            status: 'pending'
        });

        const expiredAt = Math.floor(Date.now() / 1000) + 15 * 60;
        const paymentLink = await payos.paymentRequests.create({
            orderCode,
            amount: plan.amount,
            description: 'FlowMate Pro',
            returnUrl: getReturnUrl(orderCode),
            cancelUrl: getCancelUrl(orderCode),
            expiredAt,
            buyerEmail: user.email,
            buyerName: user.name || user.email,
            buyerPhone: user.phone || undefined,
            items: [
                {
                    name: plan.name,
                    quantity: 1,
                    price: plan.amount
                }
            ]
        });

        payment.paymentLinkId = paymentLink.paymentLinkId || '';
        payment.checkoutUrl = paymentLink.checkoutUrl || '';
        payment.qrCode = paymentLink.qrCode || '';
        payment.providerStatus = paymentLink.status || 'PENDING';
        payment.rawPayload = paymentLink;
        await payment.save();

        res.status(201).json({
            orderCode,
            paymentLinkId: payment.paymentLinkId,
            checkoutUrl: payment.checkoutUrl,
            qrCode: payment.qrCode,
            amount: payment.amount,
            status: payment.status,
            plan: payment.plan
        });
    } catch (error) {
        console.error('Error in paymentController.createPayOSPaymentLink:', error);
        res.status(error.status || 500).json({ error: error.message });
    }
};

exports.getPaymentStatus = async (req, res) => {
    try {
        const orderCode = Number(req.params.orderCode);
        if (!Number.isFinite(orderCode)) {
            return res.status(400).json({ error: 'Invalid orderCode.' });
        }

        let payment = await Payment.findOne({ orderCode, user: req.user.id });
        if (!payment) return res.status(404).json({ error: 'Payment not found.' });

        try {
            payment = await syncPaymentFromPayOS(payment, req.app.get('io'));
        } catch (error) {
            console.warn('Could not sync payment from PayOS:', error.message);
        }

        const subscription = await Subscription.findOne({ user: req.user.id });
        res.status(200).json({
            orderCode: payment.orderCode,
            status: payment.status,
            providerStatus: payment.providerStatus,
            amount: payment.amount,
            plan: payment.plan,
            paidAt: payment.paidAt,
            subscription: toSubscriptionResponse(subscription)
        });
    } catch (error) {
        console.error('Error in paymentController.getPaymentStatus:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.reportAbandonedPayment = async (req, res) => {
    try {
        const orderCode = Number(req.params.orderCode);
        if (!Number.isFinite(orderCode)) {
            return res.status(400).json({ error: 'Invalid orderCode.' });
        }

        const payment = await Payment.findOne({ orderCode, user: req.user.id });
        if (!payment) return res.status(404).json({ error: 'Payment not found.' });

        if (payment.status !== 'paid') {
            await createUnpaidNotification(
                payment,
                payment.status === 'pending' ? 'abandoned' : payment.status,
                req.app.get('io')
            );
        }

        res.status(200).json({ success: true, status: payment.status });
    } catch (error) {
        console.error('Error in paymentController.reportAbandonedPayment:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.handlePayOSWebhook = async (req, res) => {
    try {
        const payos = getPayOS();
        const webhookData = await payos.webhooks.verify(req.body);
        const orderCode = Number(webhookData.orderCode);
        const payment = await Payment.findOne({ orderCode });

        if (!payment) {
            return res.status(200).json({ success: true, message: 'Payment not tracked locally.' });
        }

        payment.rawPayload = req.body;
        payment.paymentLinkId = webhookData.paymentLinkId || payment.paymentLinkId;
        payment.providerStatus = webhookData.code || '';

        if (req.body.success === true && webhookData.code === '00') {
            payment.status = 'paid';
            payment.paidAt = payment.paidAt || new Date();
            await payment.save();
            await activateSubscription(payment, req.app.get('io'));
        } else {
            payment.status = 'failed';
            await payment.save();
            await createUnpaidNotification(payment, 'failed', req.app.get('io'));
        }

        res.status(200).json({ success: true });
    } catch (error) {
        console.error('Error in paymentController.handlePayOSWebhook:', error);
        res.status(400).json({ success: false, error: error.message });
    }
};

exports.listPlans = async (_req, res) => {
    res.status(200).json({
        plans: Object.values(PLANS).map((plan) => ({
            id: plan.id,
            name: plan.name,
            label: plan.label,
            amount: plan.amount,
            durationDays: plan.durationDays
        }))
    });
};

exports.checkPayOSWebhook = async (_req, res) => {
    res.status(200).json({
        ok: true,
        message: 'PayOS webhook endpoint is ready.'
    });
};
