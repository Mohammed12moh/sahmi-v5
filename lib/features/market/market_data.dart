import 'dart:math';
import 'models.dart';

class _Seed {
  final String symbol, nameAr, sector;
  final double base;
  const _Seed(this.symbol, this.nameAr, this.sector, this.base);
}

const _seeds = [
  _Seed('AAPL', 'آبل', 'تقنية', 190),
  _Seed('MSFT', 'مايكروسوفت', 'تقنية', 410),
  _Seed('NVDA', 'إنفيديا', 'أشباه موصلات', 880),
  _Seed('AMD', 'إيه إم دي', 'أشباه موصلات', 165),
  _Seed('TSLA', 'تسلا', 'سيارات', 215),
  _Seed('AMZN', 'أمازون', 'تجزئة', 180),
  _Seed('GOOGL', 'ألفابت', 'تقنية', 150),
  _Seed('META', 'ميتا', 'تقنية', 480),
  _Seed('NFLX', 'نتفليكس', 'ترفيه', 620),
  _Seed('JPM', 'جي بي مورغان', 'بنوك', 195),
  _Seed('XOM', 'إكسون موبيل', 'طاقة', 115),
  _Seed('KO', 'كوكا كولا', 'استهلاكية', 60),
];

/// محاكي السوق: بيانات عشوائية حتمية (seeded) وليست أسعاراً حقيقية.
/// Market simulator: deterministic random walk, NOT real prices.
class MarketSimulator {
  static const history = 260;
  final _rng = Random();
  final _stocks = <String, Stock>{};

  MarketSimulator() {
    for (final s in _seeds) {
      _stocks[s.symbol] = _generate(s);
    }
  }

  static double _gauss(Random r) {
    final u1 = 1 - r.nextDouble(), u2 = r.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  Stock _generate(_Seed s) {
    final seed = s.symbol.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
    final r = Random(seed);
    final drift = (r.nextDouble() - 0.45) * 0.0012;
    final vol = 0.012 + r.nextDouble() * 0.014;
    final baseVol = 1e6 * (0.5 + r.nextDouble() * 2);
    var price = s.base;
    final closes = <double>[], vols = <double>[];
    for (var i = 0; i < history; i++) {
      final ret = drift + vol * _gauss(r);
      price = max(1.0, price * (1 + ret));
      closes.add(price);
      vols.add(baseVol * (0.7 + 0.6 * r.nextDouble()) * (1 + 6 * ret.abs()));
    }
    return Stock(
      symbol: s.symbol, nameAr: s.nameAr, sector: s.sector,
      closes: closes, volumes: vols, sentiment: (r.nextDouble() * 2 - 1) * 0.8,
    );
  }

  List<Stock> snapshot() => _stocks.values.toList();

  /// حركة سعرية صغيرة / small live tick
  void tick() {
    for (final k in _stocks.keys.toList()) {
      final s = _stocks[k]!;
      final delta = (_rng.nextDouble() - 0.5) * 0.005;
      _stocks[k] = s.withTick(max(1.0, s.price * (1 + delta)), s.volumes.last * 0.01 * _rng.nextDouble());
    }
  }
}
