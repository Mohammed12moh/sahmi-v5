import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/features/game/game_defs.dart';
import 'package:sahmi/features/portfolio/portfolio_models.dart';

void main() {
  group('portfolio math', () {
    test('holding view', () {
      const h = Holding('AAPL', 10, 100);
      final v = HoldingView(h, 110);
      expect(v.value, 1100);
      expect(v.cost, 1000);
      expect(v.pnl, 100);
      expect(v.pnlPct, closeTo(10, 1e-9));
    });
    test('zero cost safe', () => expect(const HoldingView(Holding('X', 0, 0), 5).pnlPct, 0));
    test('realized pnl counts sells only', () {
      expect(
        realizedPnl([
          {'side': 'buy', 'pnl': 0},
          {'side': 'sell', 'pnl': 25.5},
          {'side': 'sell', 'pnl': -10},
        ]),
        15.5,
      );
    });
    test('fromRow', () {
      final h = Holding.fromRow({'symbol': 'TSLA', 'qty': 3, 'avg_price': 200.5});
      expect(h.qty, 3);
      expect(h.avgPrice, 200.5);
    });
    test('error messages', () {
      expect(tradeErrorMessage('insufficient balance'), contains('غير كافٍ'));
      expect(tradeErrorMessage('insufficient holdings'), contains('للبيع'));
      expect(tradeErrorMessage('boom'), contains('تعذّرت'));
    });
  });

  group('gamification', () {
    test('challenge value handles bool and num', () {
      final open = challengeDefs.firstWhere((c) => c.id == 'daily_open');
      final week = challengeDefs.firstWhere((c) => c.id == 'weekly_trades');
      expect(challengeValue({'opened_today': true}, open), 1);
      expect(challengeValue({'opened_today': false}, open), 0);
      expect(challengeValue({'trades_week': 4}, week), 4);
      expect(challengeValue({}, week), 0);
    });
    test('badge toast', () {
      expect(badgeToast(['first_trade']), contains('أول صفقة'));
      expect(badgeToast(['first_trade', 'streak_3']), contains('+40 XP'));
    });
    test('unique ids', () {
      expect(badgeDefs.map((b) => b.id).toSet().length, badgeDefs.length);
      expect(challengeDefs.map((c) => c.id).toSet().length, challengeDefs.length);
    });
  });
}
