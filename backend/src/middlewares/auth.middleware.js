const tokenService = require('../services/token.service');
const AppError = require('../utils/appError');

function authenticate(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return next(new AppError(401, 'TOKEN_INVALID', 'Access token is missing.'));
  }

  const token = header.slice('Bearer '.length);

  try {
    const payload = tokenService.verifyAccessToken(token);
    req.user = { id: payload.sub };
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new AppError(401, 'TOKEN_EXPIRED', 'Access token has expired.'));
    }
    return next(new AppError(401, 'TOKEN_INVALID', 'Access token is invalid.'));
  }
}

module.exports = authenticate;
