// ignore_for_file: public_member_api_docs
/// Review moderation status.
enum ReviewModerationStatus {
  published,
  hidden;

  String get wireValue {
    switch (this) {
      case ReviewModerationStatus.published:
        return 'published';
      case ReviewModerationStatus.hidden:
        return 'hidden';
    }
  }

  static ReviewModerationStatus fromWire(String value) {
    switch (value) {
      case 'published':
        return ReviewModerationStatus.published;
      case 'hidden':
        return ReviewModerationStatus.hidden;
      default:
        throw const FormatException('Unknown ReviewModerationStatus.');
    }
  }
}
