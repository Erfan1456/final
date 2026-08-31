/// Centralized route constants for the Flutter client.
abstract final class AppRoutes {
  static const String splashPath = '/splash';
  static const String splashName = 'splash';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String signupPath = '/signup';
  static const String signupName = 'signup';

  static const String verifyEmailPendingPath = '/verify-email-pending';
  static const String verifyEmailPendingName = 'verifyEmailPending';

  static const String forgotPasswordPath = '/forgot-password';
  static const String forgotPasswordName = 'forgotPassword';

  static const String resetPasswordPath = '/reset-password';
  static const String resetPasswordName = 'resetPassword';

  static const String accountSecurityPath = '/account/security';
  static const String accountSecurityName = 'accountSecurity';

  static const String accountChangePasswordPath =
      '/account/security/change-password';
  static const String accountChangePasswordName = 'accountChangePassword';

  static const String accountSessionsPath = '/account/security/sessions';
  static const String accountSessionsName = 'accountSessions';

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
  static const String customerBookSlotPath =
      '/customer/book/:cleanerUserId/:slotId';
  static const String customerBookingsPath = '/customer/bookings';
  static const String customerBookingDetailPath =
      '/customer/bookings/:bookingId';
  static const String customerBookingPaymentPath =
      '/customer/bookings/:bookingId/payment';
  static const String customerBookingChatPath =
      '/customer/bookings/:bookingId/chat';
  static const String customerBookingReviewPath =
      '/customer/bookings/:bookingId/review';
  static const String customerBookingDisputePath =
      '/customer/bookings/:bookingId/dispute';

  static const String cleanerBookingsPath = '/cleaner/bookings';
  static const String cleanerBookingDetailPath = '/cleaner/bookings/:bookingId';
  static const String cleanerBookingChatPath =
      '/cleaner/bookings/:bookingId/chat';
  static const String cleanerBookingDisputePath =
      '/cleaner/bookings/:bookingId/dispute';
  static const String cleanerReviewsPath = '/cleaner/reviews';
  static const String cleanerEarningsPath = '/cleaner/earnings';
  static const String cleanerEarningsLedgerPath = '/cleaner/earnings/ledger';
  static const String cleanerPayoutsPath = '/cleaner/payouts';
  static const String cleanerPayoutRequestPath = '/cleaner/payouts/request';
  static const String cleanerPayoutDetailPath = '/cleaner/payouts/:payoutId';

  static const String notificationsPath = '/notifications';

  static const String adminHomePath = '/admin/home';
  static const String adminHomeName = 'adminHome';
  static const String adminCleanersPath = '/admin/cleaners';
  static const String adminCleanerDetailPath = '/admin/cleaners/:userId';
  static const String adminPaymentsPath = '/admin/payments';
  static const String adminPaymentDetailPath = '/admin/payments/:paymentId';
  static const String adminReviewsPath = '/admin/reviews';
  static const String adminReviewDetailPath = '/admin/reviews/:reviewId';
  static const String adminDisputesPath = '/admin/disputes';
  static const String adminDisputeDetailPath = '/admin/disputes/:disputeId';
  static const String adminUsersPath = '/admin/users';
  static const String adminUserDetailPath = '/admin/users/:userId';
  static const String adminBookingsPath = '/admin/bookings';
  static const String adminBookingDetailPath = '/admin/bookings/:bookingId';
  static const String adminAuditLogsPath = '/admin/audit-logs';
  static const String adminAuditLogDetailPath = '/admin/audit-logs/:auditLogId';
  static const String adminPayoutsPath = '/admin/payouts';
  static const String adminPayoutDetailPath = '/admin/payouts/:payoutId';
  static const String adminFinancePath = '/admin/finance';
  static const String adminFinanceReconciliationPath =
      '/admin/finance/reconciliation';
  static const String adminUserFinancePath = '/admin/users/:userId/finance';

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

  /// Payment, payout, dispute, finance, and earnings UI is retired.
  static bool isRetiredCommercePath(String location) {
    return location.contains('/payment') ||
        location.contains('/payout') ||
        location.contains('/dispute') ||
        location.contains('/finance') ||
        location.contains('/earnings');
  }

  static String customerBookSlotLocation(String cleanerUserId, String slotId) {
    return '/customer/book/$cleanerUserId/$slotId';
  }

  static String customerBookingDetailLocation(String bookingId) {
    return '/customer/bookings/$bookingId';
  }

  static String customerBookingPaymentLocation(String bookingId) {
    return '/customer/bookings/$bookingId/payment';
  }

  static String adminPaymentDetailLocation(String paymentId) {
    return '/admin/payments/$paymentId';
  }

  static String cleanerBookingDetailLocation(String bookingId) {
    return '/cleaner/bookings/$bookingId';
  }

  static String customerBookingChatLocation(String bookingId) {
    return '/customer/bookings/$bookingId/chat';
  }

  static String cleanerBookingChatLocation(String bookingId) {
    return '/cleaner/bookings/$bookingId/chat';
  }

  static String cleanerBookingDisputeLocation(String bookingId) {
    return '/cleaner/bookings/$bookingId/dispute';
  }

  static String customerBookingReviewLocation(String bookingId) {
    return '/customer/bookings/$bookingId/review';
  }

  static String customerBookingDisputeLocation(String bookingId) {
    return '/customer/bookings/$bookingId/dispute';
  }

  static String adminReviewDetailLocation(String reviewId) {
    return '/admin/reviews/$reviewId';
  }

  static String adminDisputeDetailLocation(String disputeId) {
    return '/admin/disputes/$disputeId';
  }

  static String adminUserDetailLocation(String userId) {
    return '/admin/users/$userId';
  }

  static String adminBookingDetailLocation(String bookingId) {
    return '/admin/bookings/$bookingId';
  }

  static String adminAuditLogDetailLocation(String auditLogId) {
    return '/admin/audit-logs/$auditLogId';
  }

  static String cleanerEarningsLocation() => cleanerEarningsPath;

  static String cleanerPayoutDetailLocation(String payoutId) {
    return '/cleaner/payouts/$payoutId';
  }

  static String adminPayoutDetailLocation(String payoutId) {
    return '/admin/payouts/$payoutId';
  }

  static String adminUserFinanceLocation(String userId) {
    return '/admin/users/$userId/finance';
  }

  static String verifyEmailPendingLocation({
    required String email,
    String? token,
  }) {
    final query = <String, String>{'email': email};
    if (token != null && token.isNotEmpty) {
      query['token'] = token;
    }
    return Uri(path: verifyEmailPendingPath, queryParameters: query).toString();
  }

  static String forgotPasswordLocation({String? email}) {
    if (email == null || email.isEmpty) {
      return forgotPasswordPath;
    }
    return Uri(
      path: forgotPasswordPath,
      queryParameters: <String, String>{'email': email},
    ).toString();
  }

  static String resetPasswordLocation({String? token}) {
    if (token == null || token.isEmpty) {
      return resetPasswordPath;
    }
    return Uri(
      path: resetPasswordPath,
      queryParameters: <String, String>{'token': token},
    ).toString();
  }

  /// Public auth routes reachable while signed out.
  static bool isPublicAuthPath(String location) {
    return location == loginPath ||
        location == signupPath ||
        location == verifyEmailPendingPath ||
        location == forgotPasswordPath ||
        location == resetPasswordPath;
  }
}
