const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true,
        index: true
    },
    plan: {
        type: String,
        enum: ['free', 'pro_monthly', 'pro_yearly'],
        default: 'free'
    },
    status: {
        type: String,
        enum: ['free', 'active', 'expired', 'cancelled'],
        default: 'free',
        index: true
    },
    startDate: {
        type: Date,
        default: null
    },
    endDate: {
        type: Date,
        default: null
    },
    latestPayment: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Payment',
        default: null
    },
    provider: {
        type: String,
        enum: ['manual', 'payos'],
        default: 'payos'
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Subscription', subscriptionSchema);
