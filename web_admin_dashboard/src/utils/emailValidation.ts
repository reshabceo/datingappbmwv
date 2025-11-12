/**
 * Email Validation Utility
 * Prevents sending emails to invalid addresses to avoid bounce backs
 */

// Common disposable email domains
const DISPOSABLE_EMAIL_DOMAINS = [
  '10minutemail.com', 'tempmail.com', 'guerrillamail.com', 'mailinator.com',
  'throwaway.email', 'temp-mail.org', 'getnada.com', 'mohmal.com',
  'fakeinbox.com', 'trashmail.com', 'yopmail.com', 'maildrop.cc',
  'sharklasers.com', 'spamgourmet.com', 'mintemail.com', 'emailondeck.com'
];

// Invalid email patterns
const INVALID_PATTERNS = [
  /^test@/i,
  /^admin@/i,
  /^noreply@/i,
  /^no-reply@/i,
  /^donotreply@/i,
  /@example\./i,
  /@test\./i,
  /@localhost/i,
  /@invalid\./i,
  /\.test$/i,
  /\.local$/i
];

/**
 * Validates email format using RFC 5322 compliant regex
 */
function isValidEmailFormat(email: string): boolean {
  const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
  return emailRegex.test(email);
}

/**
 * Checks if email is from a disposable email service
 */
function isDisposableEmail(email: string): boolean {
  const domain = email.split('@')[1]?.toLowerCase();
  if (!domain) return true;
  return DISPOSABLE_EMAIL_DOMAINS.some(disposable => domain.includes(disposable));
}

/**
 * Checks for invalid patterns
 */
function hasInvalidPattern(email: string): boolean {
  return INVALID_PATTERNS.some(pattern => pattern.test(email));
}

/**
 * Validates email domain format
 */
function isValidDomain(domain: string): boolean {
  if (!domain || domain.length < 3) return false;
  if (domain.startsWith('.') || domain.endsWith('.')) return false;
  if (domain.includes('..')) return false;
  const parts = domain.split('.');
  if (parts.length < 2) return false;
  return parts.every(part => part.length > 0 && /^[a-zA-Z0-9-]+$/.test(part));
}

/**
 * Comprehensive email validation
 * Returns { valid: boolean, error?: string }
 */
export function validateEmail(email: string): { valid: boolean; error?: string } {
  if (!email || typeof email !== 'string') {
    return { valid: false, error: 'Email is required' };
  }

  const trimmedEmail = email.trim().toLowerCase();

  if (trimmedEmail.length === 0) {
    return { valid: false, error: 'Email cannot be empty' };
  }

  if (trimmedEmail.length > 254) {
    return { valid: false, error: 'Email is too long' };
  }

  if (!trimmedEmail.includes('@')) {
    return { valid: false, error: 'Email must contain @ symbol' };
  }

  const [localPart, domain] = trimmedEmail.split('@');

  if (!localPart || localPart.length === 0) {
    return { valid: false, error: 'Email must have a local part' };
  }

  if (localPart.length > 64) {
    return { valid: false, error: 'Email local part is too long' };
  }

  if (!domain || domain.length === 0) {
    return { valid: false, error: 'Email must have a domain' };
  }

  if (!isValidEmailFormat(trimmedEmail)) {
    return { valid: false, error: 'Invalid email format' };
  }

  if (!isValidDomain(domain)) {
    return { valid: false, error: 'Invalid email domain' };
  }

  if (isDisposableEmail(trimmedEmail)) {
    return { valid: false, error: 'Disposable email addresses are not allowed' };
  }

  if (hasInvalidPattern(trimmedEmail)) {
    return { valid: false, error: 'Invalid email pattern' };
  }

  // Additional checks
  if (trimmedEmail.startsWith('.') || trimmedEmail.endsWith('.')) {
    return { valid: false, error: 'Email cannot start or end with a dot' };
  }

  if (trimmedEmail.includes('..')) {
    return { valid: false, error: 'Email cannot contain consecutive dots' };
  }

  return { valid: true };
}

/**
 * Quick validation check (returns boolean)
 */
export function isValidEmail(email: string): boolean {
  return validateEmail(email).valid;
}

