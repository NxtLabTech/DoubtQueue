import 'package:flutter_test/flutter_test.dart';
import 'package:doubtqueue/utils/validators.dart';

void main() {
  group('requiredField', () {
    test('returns message for null', () {
      expect(requiredField(null, 'Required'), 'Required');
    });

    test('returns message for empty input', () {
      expect(requiredField('', 'Required'), 'Required');
    });

    test('returns message for whitespace-only input', () {
      expect(requiredField('   ', 'Required'), 'Required');
    });

    test('returns null for valid input', () {
      expect(requiredField('Arrays', 'Required'), isNull);
    });
  });
}
