const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../src/config/env');
const { requireAuth } = require('../src/middleware/auth');
const { requireInstructor } = require('../src/middleware/requireInstructor');

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('requireAuth', () => {
  test('rejects a request without an Authorization header', () => {
    const res = mockRes();
    const next = jest.fn();
    requireAuth({ headers: {} }, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('rejects a token signed with the wrong secret', () => {
    const token = jwt.sign({ userId: 1, role: 'student' }, 'not-the-secret');
    const res = mockRes();
    const next = jest.fn();
    requireAuth({ headers: { authorization: `Bearer ${token}` } }, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('accepts a valid token and sets the user on the request', () => {
    const token = jwt.sign({ userId: 7, role: 'instructor' }, jwtSecret);
    const req = { headers: { authorization: `Bearer ${token}` } };
    const next = jest.fn();
    requireAuth(req, mockRes(), next);
    expect(next).toHaveBeenCalled();
    expect(req.userId).toBe(7);
    expect(req.userRole).toBe('instructor');
  });
});

describe('requireInstructor', () => {
  test('blocks a student', () => {
    const res = mockRes();
    const next = jest.fn();
    requireInstructor({ userRole: 'student' }, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });

  test('lets an instructor through', () => {
    const next = jest.fn();
    requireInstructor({ userRole: 'instructor' }, mockRes(), next);
    expect(next).toHaveBeenCalled();
  });
});
