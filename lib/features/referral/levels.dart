import 'package:flutter/material.dart';

/// مستويات الدعوة / Referral levels (مكافآتها نقاط XP رمزية)
class RefLevel {
  final String name, emoji;
  final int min;
  final int? max;
  final int xpPerFriend;
  final Color color;
  const RefLevel(this.name, this.emoji, this.min, this.max, this.xpPerFriend, this.color);
}

const refLevels = [
  RefLevel('برونز', '🥉', 0, 4, 5, Color(0xFFCD7F32)),
  RefLevel('فضة', '🥈', 5, 14, 7, Color(0xFFC0C0C0)),
  RefLevel('ذهب', '🥇', 15, 29, 10, Color(0xFFFFD700)),
  RefLevel('بلاتين', '💠', 30, 49, 15, Color(0xFFE5E4E2)),
  RefLevel('ماسي', '💎', 50, null, 20, Color(0xFF7DF9FF)),
];

RefLevel levelFor(int count) => refLevels.lastWhere((l) => count >= l.min);

RefLevel? nextLevel(int count) {
  for (final l in refLevels) {
    if (l.min > count) return l;
  }
  return null;
}

/// تقدّم نحو المستوى التالي (0..1)
double levelProgress(int count) {
  final cur = levelFor(count), next = nextLevel(count);
  if (next == null) return 1;
  return ((count - cur.min) / (next.min - cur.min)).clamp(0.0, 1.0).toDouble();
}
