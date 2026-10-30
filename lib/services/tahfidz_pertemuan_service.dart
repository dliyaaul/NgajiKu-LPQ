import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/tahfidz_pertemuan_model.dart';

class TahfidzPertemuanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'tahfidz_pertemuan';

  // ==========================================================================
  // CURRENT USER
  // ==========================================================================

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  // ==========================================================================
  // RELATIONAL SELECT
  // ==========================================================================

  String get _relationalSelect => '''
    *,
    pengajar:profiles!tahfidz_pertemuan_pengajar_id_fkey(
      id,
      username
    ),
    pengganti_pengajar:pengajar_pengganti!tahfidz_pertemuan_pengganti_pengajar_id_fkey(
      id,
      nama,
      aktif
    ),
    program:programs(
      id,
      nama
    )
  ''';

  // ==========================================================================
  // GET ALL PERTEMUAN BY PROGRAM
  // ==========================================================================

  Future<List<TahfidzPertemuanModel>> getPertemuanByProgram(
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
            (item) =>
                TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tahfidz: $e');
    }
  }

  // ==========================================================================
  // GET PERTEMUAN BERDASARKAN KELAS PENGAJARAN
  // ==========================================================================

  Future<List<TahfidzPertemuanModel>> getPertemuanByKelas({
    required String kelasPengajaranId,
  }) async {
    if (kelasPengajaranId.trim().isEmpty) {
      throw Exception('ID kelas pengajaran tidak valid.');
    }

    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (item) =>
                TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal mengambil pertemuan berdasarkan kelas: ${e.message}',
      );
    } catch (e) {
      throw Exception('Gagal mengambil pertemuan berdasarkan kelas: $e');
    }
  }

  // ==========================================================================
  // GET SINGLE PERTEMUAN
  // ==========================================================================

  Future<TahfidzPertemuanModel?> getPertemuanById(String pertemuanId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('id', pertemuanId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data pertemuan: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan: $e');
    }
  }

  // ==========================================================================
  // CREATE
  // ==========================================================================

  Future<TahfidzPertemuanModel> createPertemuan(
    TahfidzPertemuanModel model,
  ) async {
    try {
      if (model.kelasPengajaranId.trim().isEmpty) {
        throw Exception(
          'Kelas pengajaran harus dipilih sebelum membuat pertemuan.',
        );
      }

      final data = model.toMap(includeId: false, includeCreatedAt: false);

      // Pastikan created_by terisi dari user yang sedang login.
      data['created_by'] ??= currentUserId;

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect)
          .single();

      return TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal menambahkan pertemuan Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menambahkan pertemuan Tahfidz: $e');
    }
  }

  // ==========================================================================
  // UPDATE
  // ==========================================================================

  Future<TahfidzPertemuanModel> updatePertemuan(
    TahfidzPertemuanModel model,
  ) async {
    if (model.id.isEmpty) {
      throw Exception('ID pertemuan tidak valid.');
    }

    if (model.kelasPengajaranId.trim().isEmpty) {
      throw Exception('Kelas pengajaran harus dipilih.');
    }

    if (!canEdit(model)) {
      throw Exception(
        'Pertemuan hanya dapat diubah dalam waktu 24 jam setelah dibuat.',
      );
    }

    try {
      final data = model.toMap(includeId: false, includeCreatedAt: false);

      // created_by dan created_at tidak diubah
      // ketika melakukan update.

      final response = await _supabase
          .from(_table)
          .update(data)
          .eq('id', model.id)
          .select(_relationalSelect)
          .single();

      return TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui pertemuan Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memperbarui pertemuan Tahfidz: $e');
    }
  }

  // ==========================================================================
  // DELETE
  // ==========================================================================

  Future<void> deletePertemuan(String pertemuanId) async {
    if (pertemuanId.isEmpty) {
      throw Exception('ID pertemuan tidak valid.');
    }

    final existing = await getPertemuanById(pertemuanId);

    if (existing == null) {
      throw Exception('Pertemuan tidak ditemukan.');
    }

    if (!canEdit(existing)) {
      throw Exception(
        'Pertemuan hanya dapat dihapus dalam waktu 24 jam setelah dibuat.',
      );
    }

    try {
      await _supabase.from(_table).delete().eq('id', pertemuanId);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus pertemuan Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghapus pertemuan Tahfidz: $e');
    }
  }

  // ==========================================================================
  // 24 HOURS RULE
  // ==========================================================================

  bool canEdit(TahfidzPertemuanModel model) {
    final batas = model.createdAt.toLocal().add(const Duration(hours: 24));

    return DateTime.now().isBefore(batas);
  }

  bool canDelete(TahfidzPertemuanModel model) {
    return canEdit(model);
  }

  // ==========================================================================
  // REMAINING EDIT TIME
  // ==========================================================================

  Duration remainingEditDuration(TahfidzPertemuanModel model) {
    final deadline = model.createdAt.toLocal().add(const Duration(hours: 24));

    final remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ==========================================================================
  // VALIDATE TEACHER
  // ==========================================================================

  Future<bool> isPengajarTerdaftar(String programId, String pengajarId) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('id')
          .eq('program_id', programId)
          .eq('pengajar_id', pengajarId)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memeriksa pengajar: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memeriksa pengajar: $e');
    }
  }

  // ==========================================================================
  // GET SANTRI BERDASARKAN KELAS PENGAJARAN
  // ==========================================================================

  Future<List<Map<String, dynamic>>> getSantriByKelas({
    required String programId,
    required String kelasPengajaranId,
  }) async {
    if (programId.trim().isEmpty) {
      throw Exception('ID program tidak valid.');
    }

    if (kelasPengajaranId.trim().isEmpty) {
      throw Exception('ID kelas pengajaran tidak valid.');
    }

    try {
      final response = await _supabase
          .from('santri_programs')
          .select('''
            id,
            santri_id,
            program_id,
            kelas_type_id,
            kelas_pengajaran_id,
            created_at,
            santri:profiles!santri_programs_santri_id_fkey(
              id,
              username,
              nik
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data santri Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data santri Tahfidz: $e');
    }
  }

  // ==========================================================================
  // LEGACY GET SANTRI BY PROGRAM
  // ==========================================================================
  //
  // Tetap dipertahankan untuk kompatibilitas pemanggil lama.
  // Namun, kelas pengajaran wajib disertakan agar tidak mengambil
  // santri dari seluruh kelas dalam satu program.
  //

  Future<List<Map<String, dynamic>>> getSantriByProgram(
    String programId, {
    String? kelasPengajaranId,
  }) async {
    if (kelasPengajaranId == null || kelasPengajaranId.trim().isEmpty) {
      throw Exception(
        'Kelas pengajaran wajib ditentukan untuk mengambil data santri.',
      );
    }

    return getSantriByKelas(
      programId: programId,
      kelasPengajaranId: kelasPengajaranId,
    );
  }

  // ==========================================================================
  // ABSENSI TIME LIMIT
  // ==========================================================================

  bool canInputAbsensi(TahfidzPertemuanModel model) {
    final batas = model.createdAt.toLocal().add(const Duration(hours: 24));

    return DateTime.now().isBefore(batas);
  }

  Duration remainingAbsensiDuration(TahfidzPertemuanModel model) {
    final batas = model.createdAt.toLocal().add(const Duration(hours: 24));

    final remaining = batas.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }
}
