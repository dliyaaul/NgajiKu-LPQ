import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings/app_setting_model.dart';

class AppSettingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // GET ALL SETTINGS
  // ============================================================

  Future<List<AppSettingModel>> getAllSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .order('setting_key');

      return (response as List)
          .map(
            (item) => AppSettingModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pengaturan aplikasi: $e');
    }
  }

  // ============================================================
  // GET SETTING BY KEY
  // ============================================================

  Future<AppSettingModel?> getByKey(String key) async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .eq('setting_key', key)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AppSettingModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil pengaturan "$key": $e');
    }
  }

  // ============================================================
  // GET VALUE BY KEY
  // ============================================================

  Future<String?> getValue(String key) async {
    final setting = await getByKey(key);
    return setting?.settingValue;
  }

  // ============================================================
  // UPDATE SETTING
  // ============================================================

  Future<void> updateSetting({
    required String key,
    required String value,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('app_settings')
          .update({
            'setting_value': value,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': userId,
          })
          .eq('setting_key', key);
    } catch (e) {
      throw Exception('Gagal memperbarui pengaturan "$key": $e');
    }
  }
}
