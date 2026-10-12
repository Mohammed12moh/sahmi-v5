import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/features/referral/levels.dart';
import 'package:sahmi/features/wallet/deposit_rules.dart';

void main() {
  group('levels', () {
    test('thresholds', () {
      expect(levelFor(0).name, 'برونز');
      expect(levelFor(4).name, 'برونز');
      expect(levelFor(5).name, 'فضة');
      expect(levelFor(14).name, 'فضة');
      expect(levelFor(15).name, 'ذهب');
      expect(levelFor(29).name, 'ذهب');
      expect(levelFor(30).name, 'بلاتين');
      expect(levelFor(49).name, 'بلاتين');
      expect(levelFor(50).name, 'ماسي');
      expect(levelFor(500).name, 'ماسي');
    });
    test('xp per friend', () {
      expect([0, 5, 15, 30, 50].map((c) => levelFor(c).xpPerFriend), [5, 7, 10, 15, 20]);
    });
    test('next level and progress', () {
      expect(nextLevel(0)!.name, 'فضة');
      expect(nextLevel(50), isNull);
      expect(levelProgress(0), 0);
      expect(levelProgress(50), 1);
      expect(levelProgress(10), closeTo(0.5, 1e-9));
    });
  });

  group('deposit rules', () {
    test('validation', () {
      expect(validateDepositAmount(null), isNotNull);
      expect(validateDepositAmount(9.99), isNotNull);
      expect(validateDepositAmount(1000.01), isNotNull);
      expect(validateDepositAmount(10), isNull);
      expect(validateDepositAmount(1000), isNull);
    });
    test('bonus', () {
      expect(bonusFor(49.99), 0);
      expect(bonusFor(50), 5);
      expect(bonusFor(1000), 5);
    });
  });
}
