import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/features/market/market_data.dart';
import 'package:sahmi/features/market/models.dart';
import 'package:sahmi/features/market/signal_engine.dart';

void main() {
  test('action thresholds', () {
    expect(actionForScore(80), SignalAction.strongBuy);
    expect(actionForScore(79.9), SignalAction.buy);
    expect(actionForScore(65), SignalAction.buy);
    expect(actionForScore(64.9), SignalAction.hold);
    expect(actionForScore(45), SignalAction.hold);
    expect(actionForScore(44.9), SignalAction.sell);
    expect(actionForScore(35), SignalAction.sell);
    expect(actionForScore(34.9), SignalAction.strongSell);
  });

  test('all simulated stocks produce valid signals', () {
    final sim = MarketSimulator();
    final stocks = sim.snapshot();
    expect(stocks.length, 12);
    for (final s in stocks) {
      final g = SignalEngine.analyze(s);
      expect(g.score, inInclusiveRange(0, 100));
      expect(g.confidence, inInclusiveRange(40, 95));
      expect(g.reasons.length, inInclusiveRange(3, 5));
      expect(g.components.fold<double>(0, (a, c) => a + c.weight), closeTo(1.0, 1e-9));
      expect(g.riskReward, greaterThan(0));
    }
  });

  test('tick keeps history length and updates last price only', () {
    final sim = MarketSimulator();
    final before = sim.snapshot().first;
    sim.tick();
    final after = sim.snapshot().first;
    expect(after.closes.length, before.closes.length);
    expect(after.closes[after.closes.length - 2], before.closes[before.closes.length - 2]);
  });
}
