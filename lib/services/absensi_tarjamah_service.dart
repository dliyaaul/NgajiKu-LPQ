import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/absensi_tarjamah_model.dart';

class AbsensiTarjamahService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'absensi_tarjamah';

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  // ============================================================
  // RELATIONAL SELECT
  // ============================================================

  String get _relationalSelect => '''
  *,
  santri_program:santri_programs!absensi_tarjamah_santri_program_fkey(
    id,
    santri_id,
    santri:profiles!santri_programs_santri_id_fkey(
      id,
      username
    )
  )
''';

  // ============================================================
  // GET ABSENSI BERDASARKAN PERTEMUAN
  // ============================================================

  Future<List<AbsensiTarjamahModel>> getAbsensiByPertemuan(
    String tarjamahPertemuanId,
  ) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('tarjamah_pertemuan_id', tarjamahPertemuanId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) =>
                AbsensiTarjamahModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // GET ABSENSI SANTRI PADA PERTEMUAN
  // ============================================================

  Future<AbsensiTarjamahModel?> getAbsensiBySantri({
    required String tarjamahPertemuanId,
    required String santriProgramId,
  }) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('tarjamah_pertemuan_id', tarjamahPertemuanId)
          .eq('santri_program_id', santriProgramId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AbsensiTarjamahModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil absensi santri Tarjamah: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<AbsensiTarjamahModel> createAbsensi(AbsensiTarjamahModel model) async {
    try {
      final data = model.toInsertJson();

      data['created_by'] ??= currentUserId;

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect)
          .single();

      return AbsensiTarjamahModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal menambahkan absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // CREATE MANY
  // ============================================================

  Future<List<AbsensiTarjamahModel>> createManyAbsensi(
    List<AbsensiTarjamahModel> models,
  ) async {
    if (models.isEmpty) return [];

    try {
      final data = models.map((model) {
        final json = model.toInsertJson();
        json['created_by'] ??= currentUserId;
        return json;
      }).toList();

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect);

      return (response as List)
          .map(
            (json) =>
                AbsensiTarjamahModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal menyimpan beberapa absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<AbsensiTarjamahModel> updateAbsensi(AbsensiTarjamahModel model) async {
    try {
      final response = await _supabase
          .from(_table)
          .update(model.toUpdateJson())
          .eq('id', model.id)
          .select(_relationalSelect)
          .single();

      return AbsensiTarjamahModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal memperbarui absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteAbsensi(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // DELETE SEMUA ABSENSI DALAM PERTEMUAN
  // ============================================================

  Future<void> deleteAbsensiByPertemuan(String tarjamahPertemuanId) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('tarjamah_pertemuan_id', tarjamahPertemuanId);
    } catch (e) {
      throw Exception('Gagal menghapus absensi pertemuan Tarjamah: $e');
    }
  }
}
