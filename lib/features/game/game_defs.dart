/// تعريفات الشارات والتحديات / Badges & challenges definitions
class BadgeDef {
  final String id, emoji, name, desc;
  const BadgeDef(this.id, this.emoji, this.name, this.desc);
}

const badgeDefs = [
  BadgeDef('first_trade', '🎯', 'أول صفقة', 'نفّذ أول صفقة تجريبية'),
  BadgeDef('ten_trades', '🔟', 'متداول نشط', 'نفّذ 10 صفقات'),
  BadgeDef('first_profit', '💰', 'أول ربح', 'بع سهماً بربح'),
  BadgeDef('streak_3', '🔥', '3 أيام متتالية', 'ادخل التطبيق 3 أيام متتالية'),
  BadgeDef('streak_7', '⚡', 'أسبوع متواصل', 'ادخل التطبيق 7 أيام متتالية'),
  BadgeDef('first_referral', '🤝', 'أول دعوة', 'سجّل صديق برمزك'),
  BadgeDef('five_referrals', '🌟', 'سفير سهمي', 'ادعُ 5 أصدقاء'),
  BadgeDef('watchlist_5', '👀', 'مراقب ذكي', 'أضف 5 أسهم لقائمة المراقبة'),
];

String badgeToast(List<String> ids) {
  final names = [
    for (final id in ids)
      badgeDefs.where((b) => b.id == id).map((b) => '${b.emoji} ${b.name}').firstOrNull ?? id
  ];
  return 'شارة جديدة: ${names.join('، ')} (+${ids.length * 20} XP)';
}

class ChallengeDef {
  final String id, title, desc, progressKey;
  final int target, xp;
  final bool weekly;
  const ChallengeDef(this.id, this.title, this.desc, this.progressKey, this.target, this.xp, this.weekly);
}

const challengeDefs = [
  ChallengeDef('daily_open', 'حضور يومي', 'افتح التطبيق اليوم', 'opened_today', 1, 5, false),
  ChallengeDef('daily_trade', 'صفقة اليوم', 'نفّذ صفقة تجريبية واحدة', 'trades_today', 1, 10, false),
  ChallengeDef('weekly_trades', 'متداول الأسبوع', 'نفّذ 5 صفقات هذا الأسبوع', 'trades_week', 5, 40, true),
  ChallengeDef('weekly_invite', 'سفير الأسبوع', 'سجّل صديق برمزك هذا الأسبوع', 'refs_week', 1, 50, true),
];

/// قيمة التقدم كرقم (bool أو num) / progress as int
int challengeValue(Map<String, dynamic> progress, ChallengeDef c) {
  final v = progress[c.progressKey];
  if (v is bool) return v ? 1 : 0;
  if (v is num) return v.toInt();
  return 0;
}
