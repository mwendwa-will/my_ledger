import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/utils/date_range_helper.dart';

void main() {
  test('inclusive end date becomes exclusive start of following day', () {
    expect(
      exclusiveEndDate(DateTime(2025, 2, 28)),
      DateTime(2025, 3, 1),
    );
    expect(
      exclusiveEndDate(DateTime(2024, 2, 29)),
      DateTime(2024, 3, 1),
    );
  });
}
