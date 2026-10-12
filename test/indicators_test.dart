import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/features/market/indicators.dart';

void main() {
  final rising = [for (var i = 1; i <= 60; i++) i.toDouble()];
  final falling = rising.reversed.toList();
  final flat = List<double>.filled(60, 10);

  test('sma', () => expect(sma([1, 2, 3, 4, 5], 5), 3));
  test('sma null when short', () => expect(sma([1, 2], 5), isNull));
  test('rsi rising = 100', () => expect(rsi(rising, 14), 100));
  test('rsi falling is low', () => expect(rsi(falling, 14), lessThan(5)));
  test('macd rising is positive', () => expect(macd(rising).macd, greaterThan(0)));
  test('bollinger flat has zero width', () {
    final b = bollinger(flat);
    expect(b.upper, b.lower);
    expect(b.percentB(10), .5);
  });
  test('ema length', () => expect(emaSeries(rising, 12).length, rising.length));
}
