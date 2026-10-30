import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_bbaq/bbaq_pertemuan_model.dart';
import 'package:ptl_mobile/models/pengajar_program/pengajar_program_model.dart';

class AbsensiBbaqService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'bbaq_pertemuan';

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  // ============================================================
  // RELATIONAL SELECT
  // ============================================================

  String get _relationalSelect => '''
  *,
  pengajar:profiles!bbaq_pertemuan_pengajar_fkey(
    id,
    username
  ),
  pengganti_pengajar:pengajar_pengganti!bbaq_pertemuan_pengganti_pengajar_id_fkey(
    id,
    nama,
    no_hp,
    aktif
  )
''';

  // ============================================================
  // GET PENGAJAR BERDASARKAN PROGRAM
  //
  // SUMBER DATA:
  // pengajar_programs
  //
  // Relasi:
  // pengajar_programs.pengajar_id
  //      ↓
  // profiles.id
  //
  // Filter:
  // pengajar_programs.program_id = programId
  // ============================================================

  Future<List<PengajarProgramModel>> getPengajarByProgram(
    String programId,
  ) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            *,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username,
              email,
              no_hp,
              alamat,
              avatar_url,
              role
            ),
            program:programs(
              id,
              nama,
              deskripsi
            )
          ''')
          .eq('program_id', programId);

      return (response as List)
          .map(
            (json) =>
                PengajarProgramModel.fromMap(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pengajar berdasarkan program: $e');
    }
  }

  // ============================================================
  // GET ALL PERTEMUAN
  // ============================================================

  Future<List<BbaqPertemuanModel>> getAllPertemuan() async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN BY PROGRAM
  // ============================================================

  Future<List<BbaqPertemuanModel>> getPertemuanByProgram(
    String programId,
  ) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('program_id', programId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN BY ID
  // ============================================================

  Future<BbaqPertemuanModel?> getPertemuanById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil detail pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN BERDASARKAN RENTANG TANGGAL
  // ============================================================

  Future<List<BbaqPertemuanModel>> getPertemuanByDateRange({
    required String programId,
    required DateTime tanggalMulai,
    required DateTime tanggalSampai,
  }) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('program_id', programId)
          .gte('tanggal', _formatDate(tanggalMulai))
          .lte('tanggal', _formatDate(tanggalSampai))
          .order('tanggal', ascending: true);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pertemuan berdasarkan tanggal: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN BERDASARKAN PENGAJAR
  // ============================================================

  Future<List<BbaqPertemuanModel>> getPertemuanByPengajar({
    required String programId,
    required String pengajarId,
  }) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('program_id', programId)
          .eq('pengajar_id', pengajarId)
          .order('tanggal', ascending: true);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil pertemuan berdasarkan pengajar: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN UNTUK REKAP
  //
  // FILTER:
  // - PROGRAM
  // - PENGAJAR (OPSIONAL)
  // - TANGGAL MULAI
  // - TANGGAL SAMPAI
  // ============================================================

  Future<List<BbaqPertemuanModel>> getPertemuanForRekap({
    required String programId,
    String? pengajarId,
    required DateTime tanggalMulai,
    required DateTime tanggalSampai,
  }) async {
    try {
      var query = _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('program_id', programId)
          .gte('tanggal', _formatDate(tanggalMulai))
          .lte('tanggal', _formatDate(tanggalSampai));

      if (pengajarId != null && pengajarId.isNotEmpty) {
        query = query.eq('pengajar_id', pengajarId);
      }

      final response = await query.order('tanggal', ascending: true);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data rekap BBAQ: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<BbaqPertemuanModel> createPertemuan(BbaqPertemuanModel model) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(model.toInsertJson())
          .select(_relationalSelect)
          .single();

      return BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal menambahkan pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // CREATE MANY
  // ============================================================

  Future<List<BbaqPertemuanModel>> createManyPertemuan(
    List<BbaqPertemuanModel> models,
  ) async {
    try {
      if (models.isEmpty) {
        return [];
      }

      final data = models.map((model) => model.toInsertJson()).toList();

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect);

      return (response as List)
          .map(
            (json) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal menambahkan beberapa pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<BbaqPertemuanModel> updatePertemuan(BbaqPertemuanModel model) async {
    try {
      final response = await _supabase
          .from(_table)
          .update(model.toUpdateJson())
          .eq('id', model.id)
          .select(_relationalSelect)
          .single();

      return BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal memperbarui pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deletePertemuan(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  /// Mengambil pertemuan berdasarkan kelas pengajaran.
  ///
  /// Filter dilakukan langsung di Supabase agar pertemuan
  /// dari kelas lain tidak ikut ditampilkan.
  Future<List<BbaqPertemuanModel>> getPertemuanByKelas({
    required String kelasPengajaranId,
  }) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (item) =>
                BbaqPertemuanModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat pertemuan berdasarkan kelas: ${e.message}');
    }
  }
}
