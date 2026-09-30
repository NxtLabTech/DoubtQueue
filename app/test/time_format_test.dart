import 'package:doubtqueue/utils/time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseApiDate reads a UTC API date', () {
    final date = parseApiDate('2026-01-05 10:30:00');

    expect(date, DateTime.utc(2026, 1, 5, 10, 30));
    expect(date!.isUtc, isTrue);
  });

  test('parseApiDate returns null for missing or invalid values', () {
    expect(parseApiDate(null), isNull);
    expect(parseApiDate(''), isNull);
    expect(parseApiDate('not a date'), isNull);
  });

  test('timeAgo describes minutes, hours and days', () {
    final now = DateTime.utc(2026, 1, 5, 12);

    expect(timeAgo(now, now: now), 'just now');
    expect(
      timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
      '5 min ago',
    );
    expect(
      timeAgo(now.subtract(const Duration(hours: 1)), now: now),
      '1 hour ago',
    );
    expect(
      timeAgo(now.subtract(const Duration(hours: 3)), now: now),
      '3 hours ago',
    );
    expect(
      timeAgo(now.subtract(const Duration(days: 2)), now: now),
      '2 days ago',
    );
  });

  test('timeAgo returns an empty string when the time is unknown', () {
    expect(timeAgo(null), '');
  });
}
