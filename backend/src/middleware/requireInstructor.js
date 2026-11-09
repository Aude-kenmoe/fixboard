// Role is read from the JWT payload (set by requireAuth).
// No database round-trip needed — eliminates one SELECT per protected request.
function requireInstructor(req, res, next) {
  if (req.userRole !== 'instructor') {
    return res.status(403).json({ error: 'Instructor role required' });
  }
  next();
}

module.exports = { requireInstructor };
