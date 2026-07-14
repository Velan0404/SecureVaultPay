require('dotenv').config();

const { assertEnv } = require('./config/env');

assertEnv();

const app = require('./app');

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`SecureVault Pay backend running on port ${PORT}`);
});
