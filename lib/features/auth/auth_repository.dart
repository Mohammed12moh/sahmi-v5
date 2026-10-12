import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);
final authRepoProvider = Provider((ref) => AuthRepository(ref.watch(supabaseProvider)));

class RegisterData {
  String fullName = '', username = '', email = '', phone = '+964';
  DateTime? birthDate;
  String? gender, city, district, address, inviteCode;
  String password = '';
}

class AuthRepository {
  final SupabaseClient _db;
  AuthRepository(this._db);

  Future<void> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  /// فحص اسم المستخدم عبر RPC (الجدول محمي بـ RLS)
  Future<bool> usernameAvailable(String u) async {
    final r = await _db.rpc('username_available', params: {'p_username': u});
    return r == true;
  }

  /// التسجيل: البيانات تُمرَّر كـ metadata ويُنشئ الـ trigger الملف الشخصي
  Future<void> signUp(RegisterData d) async {
    await _db.auth.signUp(email: d.email.trim(), password: d.password, data: {
      'full_name': d.fullName,
      'username': d.username.toLowerCase(),
      'phone': d.phone,
      'birth_date': d.birthDate?.toIso8601String(),
      'gender': d.gender,
      'city': d.city,
      'district': d.district,
      'address': d.address,
      'invited_by_code': (d.inviteCode ?? '').trim().isEmpty ? null : d.inviteCode!.trim().toUpperCase(),
    });
  }

  /// عدد من سجلوا بالرمز / live count for invite code
  Future<int> inviteCount(String code) async {
    final r = await _db.rpc('invite_code_count', params: {'p_code': code.toUpperCase()});
    return (r as int?) ?? 0;
  }

  Future<void> signOut() => _db.auth.signOut();
}
