import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/core/password_strength.dart';

void main() {
  test('weak', () => expect(passwordStrength('abc'), PwStrength.weak));
  test('medium', () => expect(passwordStrength('abcdefgh'), PwStrength.medium));
  test('strong', () => expect(passwordStrength('Abcdefg1'), PwStrength.strong));
  test('legendary', () => expect(passwordStrength('Abcdefghijk1!'), PwStrength.legendary));
}
