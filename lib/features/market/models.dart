import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// نتيجة الإشارة / Signal action
enum SignalAction { strongBuy, buy, hold, sell, strongSell }

extension SignalActionX on SignalAction {
  String get label => switch (this) {
        SignalAction.strongBuy => 'شراء قوي',
        SignalAction.buy => 'شراء',
        SignalAction.hold => 'انتظار',
        SignalAction.sell => 'بيع',
        SignalAction.strongSell => 'بيع قوي',
      };
  String get emoji => switch (this) {
        SignalAction.strongBuy => '🟢🟢',
        SignalAction.buy => '🟢',
        SignalAction.hold => '🟡',
        SignalAction.sell => '🔴',
        SignalAction.strongSell => '🔴🔴',
      };
  Color get color => switch (this) {
        SignalAction.strongBuy || SignalAction.buy => C.green,
        SignalAction.hold => C.gold,
        SignalAction.sell || SignalAction.strongSell => C.red,
      };
}

/// 80-100 شراء قوي | 65-79 شراء | 45-64 انتظار | 35-44 بيع | 0-34 بيع قوي
SignalAction actionForScore(double s) {
  if (s >= 80) return SignalAction.strongBuy;
  if (s >= 65) return SignalAction.buy;
  if (s >= 45) return SignalAction.hold;
  if (s >= 35) return SignalAction.sell;
  return SignalAction.strongSell;
}

class SignalComponent {
  final String name, reason;
  final double weight, score;
  const SignalComponent(this.name, this.weight, this.score, this.reason);
}

class Signal {
  final double score, confidence, stopLoss, takeProfit, riskReward;
  final SignalAction action;
  final List<String> reasons;
  final List<SignalComponent> components;
  const Signal({
    required this.score, required this.confidence, required this.stopLoss,
    required this.takeProfit, required this.riskReward, required this.action,
    required this.reasons, required this.components,
  });
}

/// سهم (بيانات محاكاة) / Stock (simulated data)
class Stock {
  final String symbol, nameAr, sector;
  final List<double> closes, volumes;
  final double sentiment; // -1..1 (محاكاة)
  const Stock({
    required this.symbol, required this.nameAr, required this.sector,
    required this.closes, required this.volumes, required this.sentiment,
  });

  double get price => closes.last;
  double get prev => closes[closes.length - 2];
  double get change => price - prev;
  double get changePct => change / prev * 100;

  Stock withTick(double newPrice, double extraVolume) {
    final c = List<double>.from(closes)..[closes.length - 1] = newPrice;
    final v = List<double>.from(volumes)..[volumes.length - 1] += extraVolume;
    return Stock(symbol: symbol, nameAr: nameAr, sector: sector, closes: c, volumes: v, sentiment: sentiment);
  }
}
