/// قوة كلمة المرور: ضعيف → متوسط → قوي → أسطوري
enum PwStrength { weak, medium, strong, legendary }

PwStrength passwordStrength(String p) {
  var s = 0;
  if (p.length >= 8) s++;
  if (p.length >= 12) s++;
  if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
  if (RegExp(r'\d').hasMatch(p)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
  if (s <= 1) return PwStrength.weak;
  if (s == 2) return PwStrength.medium;
  if (s <= 4) return PwStrength.strong;
  return PwStrength.legendary;
}

const pwLabels = {
  PwStrength.weak: 'ضعيف',
  PwStrength.medium: 'متوسط',
  PwStrength.strong: 'قوي',
  PwStrength.legendary: 'أسطوري',
};
