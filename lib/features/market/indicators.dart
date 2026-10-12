import 'dart:math';

double mean(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

double stdDev(List<double> v) {
  if (v.length < 2) return 0;
  final m = mean(v);
  return sqrt(v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length);
}

/// المتوسط المتحرك البسيط / Simple moving average (آخر قيمة)
double? sma(List<double> v, int n) => v.length < n ? null : mean(v.sublist(v.length - n));

List<double> emaSeries(List<double> v, int n) {
  if (v.isEmpty) return [];
  final k = 2 / (n + 1);
  final out = <double>[v.first];
  for (var i = 1; i < v.length; i++) {
    out.add(v[i] * k + out[i - 1] * (1 - k));
  }
  return out;
}

/// RSI بطريقة Wilder
double rsi(List<double> v, int n) {
  if (v.length <= n) return 50;
  var g = 0.0, l = 0.0;
  for (var i = 1; i <= n; i++) {
    final d = v[i] - v[i - 1];
    if (d >= 0) { g += d; } else { l -= d; }
  }
  var ag = g / n, al = l / n;
  for (var i = n + 1; i < v.length; i++) {
    final d = v[i] - v[i - 1];
    ag = (ag * (n - 1) + (d > 0 ? d : 0)) / n;
    al = (al * (n - 1) + (d < 0 ? -d : 0)) / n;
  }
  if (al == 0) return 100;
  return 100 - 100 / (1 + ag / al);
}

class Macd {
  final double macd, signal, hist, prevHist;
  const Macd(this.macd, this.signal, this.hist, this.prevHist);
}

Macd macd(List<double> v) {
  final e12 = emaSeries(v, 12), e26 = emaSeries(v, 26);
  final line = [for (var i = 0; i < v.length; i++) e12[i] - e26[i]];
  final sig = emaSeries(line, 9);
  final h = line.last - sig.last;
  final ph = line.length > 1 ? line[line.length - 2] - sig[sig.length - 2] : h;
  return Macd(line.last, sig.last, h, ph);
}

class Bands {
  final double mid, upper, lower;
  const Bands(this.mid, this.upper, this.lower);
  double percentB(double p) => upper == lower ? 0.5 : (p - lower) / (upper - lower);
}

Bands bollinger(List<double> v, {int n = 20, double k = 2}) {
  final w = v.length >= n ? v.sublist(v.length - n) : v;
  final m = mean(w), sd = stdDev(w);
  return Bands(m, m + k * sd, m - k * sd);
}
