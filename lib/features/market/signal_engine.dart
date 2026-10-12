import 'indicators.dart';
import 'models.dart';

/// محرك الإشارات: RSI 25% | MA 25% | MACD 15% | Volume 15% | Bollinger 10% | أخبار 10%
/// Signals engine (educational; simulated data; not investment advice).
class SignalEngine {
  static Signal analyze(Stock s) {
    final c = s.closes, p = s.price;
    final comps = <SignalComponent>[
      _rsi(c), _ma(c, p), _macd(c), _volume(s), _bollinger(c, p), _news(s),
    ];
    final total = comps.fold<double>(0, (a, x) => a + x.weight * x.score).clamp(0.0, 100.0).toDouble();
    final spread = stdDev(comps.map((x) => x.score).toList());
    final confidence = (50 + (total - 50).abs() * 0.9 - spread * 0.3).clamp(40.0, 95.0).toDouble();

    // أهم الأسباب (3-5) / top reasons by weighted deviation from neutral
    final sorted = [...comps]..sort((a, b) =>
        ((b.score - 50).abs() * b.weight).compareTo((a.score - 50).abs() * a.weight));
    final strong = sorted.where((x) => (x.score - 50).abs() >= 8).length;
    final take = strong < 3 ? 3 : (strong > 5 ? 5 : strong);
    final reasons = sorted.take(take).map((x) => x.reason).toList();

    // وقف الخسارة/الهدف بناءً على التذبذب / volatility-based levels
    final rets = <double>[];
    final tail = c.sublist(c.length - 15);
    for (var i = 1; i < tail.length; i++) {
      rets.add((tail[i] - tail[i - 1]) / tail[i - 1]);
    }
    final atr = (stdDev(rets) * p * 1.2).clamp(p * 0.005, p * 0.2).toDouble();
    final tpMult = 2 + ((total - 50).abs() / 50) * 1.5;
    final bullish = total >= 50;
    final stop = bullish ? p - 1.5 * atr : p + 1.5 * atr;
    final target = bullish ? p + tpMult * atr : p - tpMult * atr;

    return Signal(
      score: total, action: actionForScore(total), confidence: confidence,
      stopLoss: stop, takeProfit: target, riskReward: tpMult / 1.5,
      reasons: reasons, components: comps,
    );
  }

  static double _rsiScore(double r) {
    final v = r <= 30
        ? 80 + (30 - r) / 30 * 20
        : r <= 45
            ? 60 + (45 - r) / 15 * 20
            : r <= 55
                ? 50.0
                : r <= 70
                    ? 40 - (r - 55) / 15 * 20
                    : 20 - (r - 70) / 30 * 20;
    return v.clamp(0.0, 100.0).toDouble();
  }

  static SignalComponent _rsi(List<double> c) {
    final r14 = rsi(c, 14), r7 = rsi(c, 7), r21 = rsi(c, 21);
    final score = (_rsiScore(r14) + _rsiScore(r7) + _rsiScore(r21)) / 3;
    final zone = r14 < 30 ? 'تشبّع بيعي' : r14 > 70 ? 'تشبّع شرائي' : 'منطقة محايدة';
    return SignalComponent('RSI', .25, score,
        'RSI(14) = ${r14.toStringAsFixed(1)} • $zone');
  }

  static SignalComponent _ma(List<double> c, double p) {
    var above = 0;
    for (final n in [20, 50, 100, 200]) {
      if (p > (sma(c, n) ?? p)) above++;
    }
    final m50 = sma(c, 50) ?? p, m200 = sma(c, 200) ?? p;
    final score = (15 + above * 15 + (m50 > m200 ? 10 : 0)).clamp(0, 100).toDouble();
    return SignalComponent('المتوسطات', .25, score,
        'السعر أعلى من $above من 4 متوسطات متحركة • MA50 ${m50 > m200 ? 'فوق' : 'تحت'} MA200');
  }

  static SignalComponent _macd(List<double> c) {
    final m = macd(c);
    final rising = m.hist > m.prevHist;
    final score = m.hist > 0 ? (rising ? 75.0 : 62.0) : (rising ? 38.0 : 25.0);
    return SignalComponent('MACD', .15, score,
        'MACD ${m.hist > 0 ? 'إيجابي' : 'سلبي'} والزخم ${rising ? 'يتحسّن' : 'يضعف'}');
  }

  static SignalComponent _volume(Stock s) {
    final avg = mean(s.volumes.sublist(s.volumes.length - 20));
    final ratio = avg == 0 ? 1.0 : s.volumes.last / avg;
    final up = s.change >= 0;
    final score = up ? (ratio > 1.2 ? 75.0 : 58.0) : (ratio > 1.2 ? 25.0 : 42.0);
    return SignalComponent('الحجم', .15, score,
        'حجم التداول ${ratio.toStringAsFixed(1)}x من المتوسط مع حركة ${up ? 'صاعدة' : 'هابطة'}');
  }

  static SignalComponent _bollinger(List<double> c, double p) {
    final pb = bollinger(c).percentB(p);
    final score = pb < .1 ? 80.0 : pb < .3 ? 65.0 : pb < .7 ? 50.0 : pb < .9 ? 35.0 : 20.0;
    return SignalComponent('بولينجر', .10, score,
        'السعر عند ${(pb * 100).round()}% من نطاق بولينجر');
  }

  static SignalComponent _news(Stock s) {
    final score = (50 + s.sentiment * 40).clamp(0.0, 100.0).toDouble();
    final tone = s.sentiment > .2 ? 'إيجابية' : s.sentiment < -.2 ? 'سلبية' : 'محايدة';
    return SignalComponent('الأخبار', .10, score, 'معنويات الأخبار (محاكاة) $tone');
  }
}
