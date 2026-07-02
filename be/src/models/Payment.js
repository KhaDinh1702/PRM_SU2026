const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    provider: {
        type: String,
        enum: ['payos'],
        default: 'payos'
    },
    plan: {
        type: String,
        enum: ['pro_monthly', 'pro_yearly'],
        required: true
    },
    orderCode: {
        type: Number,
        required: true,
        unique: true,
        index: true
    },
    paymentLinkId: {
        type: String,
        trim: true,
        default: ''
    },
    amount: {
        type: Number,
        required: true
    },
    description: {
        type: String,
        trim: true,
        default: ''
    },
    checkoutUrl: {
        type: String,
        trim: true,
        default: ''
    },
    qrCode: {
        type: String,
        trim: true,
        default: ''
    },
    status: {
        type: String,
        enum: ['pending', 'paid', 'cancelled', 'expired', 'failed'],
        default: 'pending',
        index: true
    },
    providerStatus: {
        type: String,
        trim: true,
        default: ''
    },
    paidAt: {
        type: Date,
        default: null
    },
    rawPayload: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    }
}, {
    timestamps: true
});

paymentSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Payment', paymentSchema);
