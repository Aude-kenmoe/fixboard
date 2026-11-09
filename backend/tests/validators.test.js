const { isValidEmail } = require('../src/utils/validators');
const { getInitials } = require('../src/utils/initials');

describe('isValidEmail', () => {
  test('accepts a normal address', () => {
    expect(isValidEmail('student@example.com')).toBe(true);
  });

  test('rejects an address without a domain dot', () => {
    expect(isValidEmail('student@example')).toBe(false);
  });

  test('rejects an address with spaces', () => {
    expect(isValidEmail('stu dent@example.com')).toBe(false);
  });

  test('rejects values that are not strings', () => {
    expect(isValidEmail(undefined)).toBe(false);
    expect(isValidEmail(42)).toBe(false);
  });
});

describe('getInitials', () => {
  test('uses the first and last word of a full name', () => {
    expect(getInitials('Ada Lovelace King')).toBe('AK');
  });

  test('uses the first two letters of a single name', () => {
    expect(getInitials('freensh')).toBe('FR');
  });

  test('returns an empty string for blank input', () => {
    expect(getInitials('   ')).toBe('');
  });
});
