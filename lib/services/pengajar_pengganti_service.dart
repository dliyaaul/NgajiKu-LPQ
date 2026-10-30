import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pengajar_pengganti/pengajar_pengganti_model.dart';

class PengajarPenggantiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'pengajar_pengganti';

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<PengajarPenggantiModel>> getAll({bool hanyaAktif = false}) async {
    try {
      dynamic query = _supabase.from(_table).select();

      if (hanyaAktif) {
        query = query.eq('aktif', true);
      }

      query = query.order('nama', ascending: true);

      final response = await query;

      return (response as List)
          .map(
            (item) =>
                PengajarPenggantiModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pengajar pengganti: $e');
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<PengajarPenggantiModel?> getById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return PengajarPenggantiModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal mengambil data pengajar pengganti: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<PengajarPenggantiModel> create(PengajarPenggantiModel model) async {
    try {
      final user = _supabase.auth.currentUser;

      final data = model.toMap(includeCreatedBy: user != null);

      if (user != null) {
        data['created_by'] = user.id;
      }

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select()
          .single();

      return PengajarPenggantiModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal menambahkan pengajar pengganti: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<PengajarPenggantiModel> update(PengajarPenggantiModel model) async {
    try {
      final data = model.toMap();

      final response = await _supabase
          .from(_table)
          .update(data)
          .eq('id', model.id)
          .select()
          .single();

      return PengajarPenggantiModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal memperbarui pengajar pengganti: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus pengajar pengganti: $e');
    }
  }

  // ============================================================
  // TOGGLE AKTIF
  // ============================================================

  Future<PengajarPenggantiModel> setAktif(String id, bool aktif) async {
    try {
      final response = await _supabase
          .from(_table)
          .update({'aktif': aktif})
          .eq('id', id)
          .select()
          .single();

      return PengajarPenggantiModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal mengubah status pengajar pengganti: $e');
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<PengajarPenggantiModel>> search(
    String keyword, {
    bool hanyaAktif = false,
  }) async {
    try {
      final trimmed = keyword.trim();

      dynamic query = _supabase.from(_table).select();

      if (trimmed.isNotEmpty) {
        query = query.ilike('nama', '%$trimmed%');
      }

      if (hanyaAktif) {
        query = query.eq('aktif', true);
      }

      query = query.order('nama', ascending: true);

      final response = await query;

      return (response as List)
          .map(
            (item) =>
                PengajarPenggantiModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mencari pengajar pengganti: $e');
    }
  }
}
