const AppError = require('../utils/appError');

function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      const details = result.error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      }));
      const error = new AppError(400, 'VALIDATION_ERROR', 'Request validation failed.');
      error.details = details;
      return next(error);
    }

    req.body = result.data;
    next();
  };
}

module.exports = validate;
