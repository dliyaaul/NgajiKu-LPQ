import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kelas/kelas_type_model.dart';

class KelasTypeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<KelasTypeModel>> getAllKelasTypes() async {
    try {
      final response = await _supabase
          .from('kelas_types')
          .select()
          .order('nama');

      return (response as List)
          .map(
            (item) => KelasTypeModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil jenis kelas: $e');
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<KelasTypeModel?> getKelasTypeById(String id) async {
    try {
      final response = await _supabase
          .from('kelas_types')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return KelasTypeModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil jenis kelas: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<KelasTypeModel> createKelasType({required String nama}) async {
    try {
      final response = await _supabase
          .from('kelas_types')
          .insert({'nama': nama})
          .select()
          .single();

      return KelasTypeModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal menambahkan jenis kelas: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<KelasTypeModel> updateKelasType({
    required String id,
    required String nama,
  }) async {
    try {
      final response = await _supabase
          .from('kelas_types')
          .update({'nama': nama})
          .eq('id', id)
          .select()
          .single();

      return KelasTypeModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal memperbarui jenis kelas: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteKelasType(String id) async {
    try {
      await _supabase.from('kelas_types').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus jenis kelas: $e');
    }
  }
}
