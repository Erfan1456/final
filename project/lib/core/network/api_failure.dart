/// Safe client failure for marketplace feature APIs.
class ApiFailure implements Exception {
  /// Creates a sanitized failure.
  const ApiFailure({required this.code, required this.message});

  /// Machine-readable code from the backend or a local client code.
  final String code;

  /// Safe user-readable message.
  final String message;

  @override
  String toString() => 'ApiFailure($code)';
}

/// User-readable messages for known backend error codes.
String messageForApiCode(String code) {
  switch (code) {
    case 'forbidden':
      return 'You do not have permission to perform this action.';
    case 'account_unavailable':
      return 'This account is currently unavailable.';
    case 'customer_profile_required':
      return 'Create your profile before setting a default address.';
    case 'address_not_found':
      return 'Address was not found.';
    case 'address_limit_reached':
      return 'You can save at most 20 addresses.';
    case 'cleaner_profile_required':
      return 'Save your cleaner profile before submitting for review.';
    case 'cleaner_profile_locked':
      return 'This profile cannot be edited while it is under review or approved.';
    case 'invalid_onboarding_state':
      return 'This onboarding action is not allowed right now.';
    case 'cleaner_application_not_found':
      return 'Cleaner application was not found.';
    case 'invalid_input':
      return 'Please check your details and try again.';
    case 'invalid_access_token':
      return 'Authentication is required.';
    case 'invalid_json':
      return 'Please check your details and try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
