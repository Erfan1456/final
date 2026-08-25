/// Centralized route constants for the Flutter client.
abstract final class AppRoutes {
  static const String splashPath = '/splash';
  static const String splashName = 'splash';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String signupPath = '/signup';
  static const String signupName = 'signup';

  static const String homePath = '/home';
  static const String homeName = 'home';

  static const String customerHomePath = '/customer/home';
  static const String customerHomeName = 'customerHome';
  static const String customerProfilePath = '/customer/profile';
  static const String customerAddressesPath = '/customer/addresses';
  static const String customerAddressNewPath = '/customer/addresses/new';
  static const String customerAddressEditPath =
      '/customer/addresses/:addressId/edit';

  static const String cleanerHomePath = '/cleaner/home';
  static const String cleanerHomeName = 'cleanerHome';
  static const String cleanerOnboardingPath = '/cleaner/onboarding';
  static const String cleanerServicesPath = '/cleaner/services';
  static const String cleanerAvailabilityPath = '/cleaner/availability';
  static const String cleanerAvailabilityNewPath = '/cleaner/availability/new';
  static const String cleanerAvailabilityEditPath =
      '/cleaner/availability/:slotId/edit';

  static const String customerDiscoverPath = '/customer/discover';
  static const String customerCleanerDetailPath =
      '/customer/cleaners/:cleanerUserId';
  static const String customerComparePath = '/customer/compare';

  static const String adminHomePath = '/admin/home';
  static const String adminHomeName = 'adminHome';
  static const String adminCleanersPath = '/admin/cleaners';
  static const String adminCleanerDetailPath = '/admin/cleaners/:userId';

  /// Role-specific authenticated home.
  static String homeForRole(String role) {
    switch (role) {
      case 'cleaner':
        return cleanerHomePath;
      case 'admin':
        return adminHomePath;
      default:
        return customerHomePath;
    }
  }

  /// Whether [location] belongs to another role than [role].
  static bool isForeignRolePath(String location, String role) {
    final isCustomer = location.startsWith('/customer');
    final isCleaner = location.startsWith('/cleaner');
    final isAdmin = location.startsWith('/admin');
    if (role == 'customer' && (isCleaner || isAdmin)) {
      return true;
    }
    if (role == 'cleaner' && (isCustomer || isAdmin)) {
      return true;
    }
    if (role == 'admin' && (isCustomer || isCleaner)) {
      return true;
    }
    return false;
  }
}
