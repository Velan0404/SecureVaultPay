const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./routes/auth.routes');
const walletRoutes = require('./routes/wallet.routes');
const transactionAuthRoutes = require('./routes/transaction_auth.routes');
const merchantRoutes = require('./routes/merchant.routes');
const paymentPinRoutes = require('./routes/paymentPin.routes');
const qrRoutes = require('./routes/qr.routes');
const personalPaymentRoutes = require('./routes/personalPayment.routes');
const scheduledPaymentRoutes = require('./routes/scheduledPayment.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const errorHandler = require('./middlewares/error.middleware');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/transaction-auth', transactionAuthRoutes);
app.use('/api/merchant', merchantRoutes);
app.use('/api/payment-pin', paymentPinRoutes);
app.use('/api/qr', qrRoutes);
app.use('/api/personal-payment', personalPaymentRoutes);
app.use('/api/scheduled-payments', scheduledPaymentRoutes);
app.use('/api/analytics', analyticsRoutes);

app.use(errorHandler);

module.exports = app;
