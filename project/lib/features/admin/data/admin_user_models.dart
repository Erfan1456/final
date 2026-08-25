import 'package:home_cleaning_marketplace/features/auth/domain/auth_user.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.role,
    required this.email,
    required this.accountStatus,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.onboardingStatus,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    final user = AuthUser.fromJson(json);
    return AdminUserSummary(
      id: user.id,
      role: user.role,
      email: user.email,
      accountStatus: user.accountStatus,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      fullName: json['full_name'] is String
          ? json['full_name'] as String
          : null,
      onboardingStatus: json['onboarding_status'] is String
          ? json['onboarding_status'] as String
          : null,
    );
  }

  final String id;
  final String role;
  final String email;
  final String accountStatus;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fullName;
  final String? onboardingStatus;

  bool get isAdmin => role == 'admin';

  String get displayName => fullName ?? email;
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.protectedAdminAccount,
    required this.bookingCount,
    required this.paymentCount,
    required this.activeDisputeCount,
    this.customerProfile,
    this.cleanerProfile,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map) {
      throw const FormatException('Admin user JSON is invalid.');
    }
    final profile = json['profile'];
    final parsedUser = AdminUserSummary.fromJson(
      Map<String, dynamic>.from(user),
    );
    CustomerProfile? customer;
    CleanerProfile? cleaner;
    if (profile is Map) {
      final map = Map<String, dynamic>.from(profile);
      if (parsedUser.role == 'customer') {
        customer = CustomerProfile.fromJson(map);
      } else if (parsedUser.role == 'cleaner') {
        cleaner = CleanerProfile.fromJson(map);
      }
    }
    return AdminUserDetail(
      user: parsedUser,
      protectedAdminAccount: json['protected_admin_account'] == true,
      bookingCount: json['booking_count'] is int
          ? json['booking_count'] as int
          : 0,
      paymentCount: json['payment_count'] is int
          ? json['payment_count'] as int
          : 0,
      activeDisputeCount: json['active_dispute_count'] is int
          ? json['active_dispute_count'] as int
          : 0,
      customerProfile: customer,
      cleanerProfile: cleaner,
    );
  }

  final AdminUserSummary user;
  final bool protectedAdminAccount;
  final int bookingCount;
  final int paymentCount;
  final int activeDisputeCount;
  final CustomerProfile? customerProfile;
  final CleanerProfile? cleanerProfile;
}

class AdminUserPage {
  const AdminUserPage({required this.items, this.nextCursor});

  final List<AdminUserSummary> items;
  final String? nextCursor;
}
