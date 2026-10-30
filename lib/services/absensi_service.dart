import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/absensi/absensi_model.dart';

class AbsensiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // RELATIONAL SELECT
  // ============================================================

  String get _relationalSelect => '''
    *,
    santri_program:santri_programs(
      *,
      santri:profiles!santri_programs_santri_id_fkey(*),
      pengajar:profiles!santri_programs_pengajar_id_fkey(*),
      program:programs(*),
      kelas_type:kelas_types(*)
    ),
    user:profiles!absensi_user_id_fkey(*),
    created_by_profile:profiles!absensi_created_by_fkey(*)
  ''';

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<AbsensiModel>> getAll() async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data absensi: $e');
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<AbsensiModel?> getById(String id) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AbsensiModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil detail absensi: $e');
    }
  }

  // ============================================================
  // GET BY SANTRI PROGRAM
  // ============================================================

  Future<List<AbsensiModel>> getBySantriProgram(String santriProgramId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('santri_program_id', santriProgramId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi program santri: $e');
    }
  }

  // ============================================================
  // GET BY USER
  // ============================================================

  Future<List<AbsensiModel>> getByUser(String userId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('user_id', userId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi user: $e');
    }
  }

  // ============================================================
  // GET BY CREATED BY
  // ============================================================

  Future<List<AbsensiModel>> getByCreatedBy(String profileId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('created_by', profileId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data absensi berdasarkan pembuat: $e');
    }
  }

  // ============================================================
  // GET BY TANGGAL
  // ============================================================

  Future<List<AbsensiModel>> getByTanggal(DateTime tanggal) async {
    try {
      final dateString = tanggal.toIso8601String().split('T').first;

      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('tanggal', dateString)
          .order('created_by', ascending: true);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi tanggal $tanggal: $e');
    }
  }

  // ============================================================
  // GET BY RENTANG TANGGAL
  // ============================================================

  Future<List<AbsensiModel>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final start = startDate.toIso8601String().split('T').first;

      final end = endDate.toIso8601String().split('T').first;

      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .gte('tanggal', start)
          .lte('tanggal', end)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil riwayat absensi: $e');
    }
  }

  // ============================================================
  // GET BY STATUS
  // ============================================================

  Future<List<AbsensiModel>> getByStatus(String status) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('status', status)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi dengan status $status: $e');
    }
  }

  // ============================================================
  // GET BY PROGRAM
  // ============================================================

  Future<List<AbsensiModel>> getByProgram(String programId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('santri_program.program_id', programId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi berdasarkan program: $e');
    }
  }

  // ============================================================
  // GET BY SANTRI
  // ============================================================

  Future<List<AbsensiModel>> getBySantri(String santriId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('santri_program.santri_id', santriId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi santri: $e');
    }
  }

  // ============================================================
  // GET BY PENGAJAR
  // ============================================================

  Future<List<AbsensiModel>> getByPengajar(String pengajarId) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select(_relationalSelect)
          .eq('santri_program.pengajar_id', pengajarId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map((item) => AbsensiModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil absensi pengajar: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<AbsensiModel> create(AbsensiModel data) async {
    try {
      final response = await _supabase
          .from('absensi')
          .insert({
            'santri_program_id': data.santriProgramId,
            'user_id': data.userId,
            'created_by': data.createdBy,
            'tanggal': data.tanggal.toIso8601String().split('T').first,
            'pbm_aktual': data.pbmAktual,
            'status': data.status,
            'catatan': data.catatan,
          })
          .select(_relationalSelect)
          .single();

      return AbsensiModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal menambahkan absensi: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<AbsensiModel> update(AbsensiModel data) async {
    try {
      final response = await _supabase
          .from('absensi')
          .update({
            'santri_program_id': data.santriProgramId,
            'user_id': data.userId,
            'created_by': data.createdBy,
            'tanggal': data.tanggal.toIso8601String().split('T').first,
            'pbm_aktual': data.pbmAktual,
            'status': data.status,
            'catatan': data.catatan,
          })
          .eq('id', data.id)
          .select(_relationalSelect)
          .single();

      return AbsensiModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal memperbarui absensi: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(String id) async {
    try {
      await _supabase.from('absensi').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus absensi: $e');
    }
  }
}
