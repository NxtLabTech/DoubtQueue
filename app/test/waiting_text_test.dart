import 'package:doubtqueue/utils/waiting_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waitingText uses the same wording for every count', () {
    expect(waitingText(0), 'No students waiting');
    expect(waitingText(1), '1 student waiting');
    expect(waitingText(2), '2 students waiting');
    expect(waitingText(25), '25 students waiting');
  });
}
