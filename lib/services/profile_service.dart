import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil semua profile
  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ProfileModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data profile: $e');
    }
  }

  /// Mengambil profile berdasarkan ID
  Future<ProfileModel?> getProfileById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ProfileModel.fromMap(response);
    } catch (e) {
      throw Exception('Gagal mengambil profile: $e');
    }
  }

  /// Mengambil profile berdasarkan role
  Future<List<ProfileModel>> getProfilesByRole(String role) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', role)
          .order('username');

      return (response as List)
          .map((item) => ProfileModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data $role: $e');
    }
  }

  /// Mengambil semua santri
  Future<List<ProfileModel>> getSantri() async {
    return getProfilesByRole('santri');
  }

  /// Mengambil semua pengajar
  Future<List<ProfileModel>> getPengajar() async {
    return getProfilesByRole('pengajar');
  }

  /// Mengambil semua staff
  Future<List<ProfileModel>> getStaff() async {
    return getProfilesByRole('staff');
  }

  /// Mengambil semua admin
  Future<List<ProfileModel>> getAdmin() async {
    return getProfilesByRole('admin');
  }

  /// Mengambil santri berdasarkan lembaga
  Future<List<ProfileModel>> getSantriByLembaga(String lembagaId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'santri')
          .eq('lembaga_id', lembagaId)
          .order('username');

      return (response as List)
          .map((item) => ProfileModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil santri lembaga: $e');
    }
  }

  /// Update profile
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id)
          .select()
          .single();

      return ProfileModel.fromMap(response);
    } catch (e) {
      throw Exception('Gagal memperbarui profile: $e');
    }
  }

  /// Menghapus profile
  Future<void> deleteProfile(String id) async {
    try {
      await _supabase.from('profiles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus profile: $e');
    }
  }
}
