import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_window.dart';

void main() {
  test('nextValidStart is at least one hour ahead and 30-minute aligned', () {
    final now = DateTime(2026, 9, 1, 3, 18, 40);
    final start = AvailabilityWindow.nextValidStart(now);
    expect(start.isAfter(now.add(const Duration(minutes: 59))), isTrue);
    expect(start.minute % 30, equals(0));
    expect(start.second, equals(0));
  });

  test('rejects windows that are too short, too long, or not 30-minute steps', () {
    final now = DateTime(2026, 9, 1, 3, 0);
    final start = DateTime(2026, 9, 1, 10, 0);
    expect(
      AvailabilityWindow.validate(
        start: start,
        end: start.add(const Duration(minutes: 45)),
        now: now,
      ),
      contains('60 minutes'),
    );
    expect(
      AvailabilityWindow.validate(
        start: start,
        end: start.add(const Duration(hours: 9)),
        now: now,
      ),
      contains('8 hours'),
    );
    expect(
      AvailabilityWindow.validate(
        start: start,
        end: start.add(const Duration(minutes: 90)),
        now: now,
      ),
      isNull,
    );
  });
}
