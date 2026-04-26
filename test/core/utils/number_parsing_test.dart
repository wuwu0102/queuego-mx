import 'package:flutter_test/flutter_test.dart';
import 'package:queuego_mx/core/utils/number_parsing.dart';

void main() {
  group('roundToTen', () {
    test('rounds to nearest 10 for typical values', () {
      expect(roundToTen(433), 430);
      expect(roundToTen(459), 460);
      expect(roundToTen(931), 930);
    });

    test('matches publish task examples', () {
      expect(roundToTen(437), 440);
      expect(roundToTen(451), 450);
    });
  });
}
