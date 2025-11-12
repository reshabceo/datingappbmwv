/// Email Validation Utility for Flutter
/// Prevents sending emails to invalid addresses to avoid bounce backs

class EmailValidation {
  // Common disposable email domains
  static const List<String> _disposableEmailDomains = [
    '10minutemail.com',
    'tempmail.com',
    'guerrillamail.com',
    'mailinator.com',
    'throwaway.email',
    'temp-mail.org',
    'getnada.com',
    'mohmal.com',
    'fakeinbox.com',
    'trashmail.com',
    'yopmail.com',
    'maildrop.cc',
    'sharklasers.com',
    'spamgourmet.com',
    'mintemail.com',
    'emailondeck.com',
  ];

  /// Validates email format using RFC 5322 compliant regex
  static bool _isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    return emailRegex.hasMatch(email);
  }

  /// Checks if email is from a disposable email service
  static bool _isDisposableEmail(String email) {
    final domain = email.split('@').length > 1 ? email.split('@')[1].toLowerCase() : '';
    if (domain.isEmpty) return true;
    return _disposableEmailDomains.any((disposable) => domain.contains(disposable));
  }

  /// Checks for invalid patterns
  static bool _hasInvalidPattern(String email) {
    final invalidPatterns = [
      RegExp(r'^test@', caseSensitive: false),
      RegExp(r'^admin@', caseSensitive: false),
      RegExp(r'^noreply@', caseSensitive: false),
      RegExp(r'^no-reply@', caseSensitive: false),
      RegExp(r'^donotreply@', caseSensitive: false),
      RegExp(r'@example\.', caseSensitive: false),
      RegExp(r'@test\.', caseSensitive: false),
      RegExp(r'@localhost', caseSensitive: false),
      RegExp(r'@invalid\.', caseSensitive: false),
      RegExp(r'\.test$', caseSensitive: false),
      RegExp(r'\.local$', caseSensitive: false),
    ];
    return invalidPatterns.any((pattern) => pattern.hasMatch(email));
  }

  /// Validates email domain format
  static bool _isValidDomain(String domain) {
    if (domain.isEmpty || domain.length < 3) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    if (domain.contains('..')) return false;
    final parts = domain.split('.');
    if (parts.length < 2) return false;
    final domainRegex = RegExp(r'^[a-zA-Z0-9-]+$');
    return parts.every((part) => part.isNotEmpty && domainRegex.hasMatch(part));
  }

  /// Comprehensive email validation
  /// Returns EmailValidationResult with valid flag and optional error message
  static EmailValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return EmailValidationResult(valid: false, error: 'Email is required');
    }

    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.isEmpty) {
      return EmailValidationResult(valid: false, error: 'Email cannot be empty');
    }

    if (trimmedEmail.length > 254) {
      return EmailValidationResult(valid: false, error: 'Email is too long');
    }

    if (!trimmedEmail.contains('@')) {
      return EmailValidationResult(valid: false, error: 'Email must contain @ symbol');
    }

    final parts = trimmedEmail.split('@');
    if (parts.length != 2) {
      return EmailValidationResult(valid: false, error: 'Invalid email format');
    }

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.isEmpty) {
      return EmailValidationResult(valid: false, error: 'Email must have a local part');
    }

    if (localPart.length > 64) {
      return EmailValidationResult(valid: false, error: 'Email local part is too long');
    }

    if (domain.isEmpty) {
      return EmailValidationResult(valid: false, error: 'Email must have a domain');
    }

    if (!_isValidEmailFormat(trimmedEmail)) {
      return EmailValidationResult(valid: false, error: 'Invalid email format');
    }

    if (!_isValidDomain(domain)) {
      return EmailValidationResult(valid: false, error: 'Invalid email domain');
    }

    if (_isDisposableEmail(trimmedEmail)) {
      return EmailValidationResult(valid: false, error: 'Disposable email addresses are not allowed');
    }

    if (_hasInvalidPattern(trimmedEmail)) {
      return EmailValidationResult(valid: false, error: 'Invalid email pattern');
    }

    // Additional checks
    if (trimmedEmail.startsWith('.') || trimmedEmail.endsWith('.')) {
      return EmailValidationResult(valid: false, error: 'Email cannot start or end with a dot');
    }

    if (trimmedEmail.contains('..')) {
      return EmailValidationResult(valid: false, error: 'Email cannot contain consecutive dots');
    }

    return EmailValidationResult(valid: true);
  }

  /// Quick validation check (returns boolean)
  static bool isValidEmail(String? email) {
    return validateEmail(email).valid;
  }
}

/// Result class for email validation
class EmailValidationResult {
  final bool valid;
  final String? error;

  EmailValidationResult({required this.valid, this.error});
}

