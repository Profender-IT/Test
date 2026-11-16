import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../supabase/providers.dart';

class Profile {
  const Profile({required this.id, this.displayName, this.department});

  final String id;
  final String? displayName;
  final String? department;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    department: json['department'] as String?,
  );
}

/// โปรไฟล์ของผู้ใช้ที่ล็อกอิน · RLS ให้อ่านได้แค่แถวของตัวเอง (supabase/migrations/*_profiles.sql)
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('id, display_name, department')
      .eq('id', user.id)
      .maybeSingle();
  return row == null ? null : Profile.fromJson(row);
});
