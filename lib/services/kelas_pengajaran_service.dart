import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kelas/kelas_pengajaran_model.dart';

class KelasPengajaranService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _selectQuery = '''
    id,
    program_id,
    kelas_type_id,
    nama_kelas,
    pengajar_id,
    lembaga_id,
    aktif,
    created_at,
    updated_at,
    programs:programs!kelas_pengajaran_program_id_fkey(nama),
    kelas_types:kelas_types!kelas_pengajaran_kelas_type_id_fkey(nama),
    pengajar:profiles!kelas_pengajaran_pengajar_id_fkey(id,username,role)
  ''';

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<KelasPengajaranModel>> getAll() async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .order('nama_kelas');

      return _mapList(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat kelas: ${e.message}');
    }
  }

  // ============================================================
  // GET ACTIVE
  // Mengambil semua kelas yang aktif.
  // ============================================================

  Future<List<KelasPengajaranModel>> getActive() async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .eq('aktif', true)
          .order('nama_kelas');

      return _mapList(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat kelas aktif: ${e.message}');
    }
  }

  // ============================================================
  // GET BY KELAS TYPE
  // Mengambil kelas berdasarkan jenis kelas.
  // Contoh: semua kelas Reguler.
  // ============================================================

  Future<List<KelasPengajaranModel>> getByKelasType(String kelasTypeId) async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .eq('kelas_type_id', kelasTypeId)
          .order('nama_kelas');

      return _mapList(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal memuat kelas berdasarkan jenis kelas: ${e.message}',
      );
    }
  }

  // ============================================================
  // GET ACTIVE BY KELAS TYPE
  // Mengambil kelas aktif untuk satu jenis kelas.
  // Cocok untuk pilihan kelas saat pendaftaran santri.
  // ============================================================

  Future<List<KelasPengajaranModel>> getActiveByKelasType(
    String kelasTypeId,
  ) async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .eq('kelas_type_id', kelasTypeId)
          .eq('aktif', true)
          .order('nama_kelas');

      return _mapList(response);
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal memuat kelas aktif berdasarkan jenis kelas: ${e.message}',
      );
    }
  }

  // ============================================================
  // GET BY PROGRAM
  // Mengambil kelas berdasarkan program.
  // Contoh: seluruh kelas BBAQ.
  // ============================================================

  Future<List<KelasPengajaranModel>> getByProgram(String programId) async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .eq('program_id', programId)
          .order('nama_kelas');

      return _mapList(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat kelas berdasarkan program: ${e.message}');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<KelasPengajaranModel> create({
    required String programId,
    required String kelasTypeId,
    required String namaKelas,
    String? pengajarId,
    String? lembagaId,
  }) async {
    if (namaKelas.trim().isEmpty) {
      throw Exception('Nama kelas tidak boleh kosong.');
    }

    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .insert({
            'program_id': programId,
            'kelas_type_id': kelasTypeId,
            'nama_kelas': namaKelas.trim(),
            'pengajar_id': pengajarId,
            'lembaga_id': lembagaId,
            'created_by': _supabase.auth.currentUser?.id,
            'aktif': true,
          })
          .select(_selectQuery)
          .single();

      return KelasPengajaranModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal menambahkan kelas: ${e.message}');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<KelasPengajaranModel> update({
    required String id,
    required String programId,
    required String kelasTypeId,
    required String namaKelas,
    String? pengajarId,
    String? lembagaId,
  }) async {
    if (namaKelas.trim().isEmpty) {
      throw Exception('Nama kelas tidak boleh kosong.');
    }

    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .update({
            'program_id': programId,
            'kelas_type_id': kelasTypeId,
            'nama_kelas': namaKelas.trim(),
            'pengajar_id': pengajarId,
            'lembaga_id': lembagaId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select(_selectQuery)
          .single();

      return KelasPengajaranModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui kelas: ${e.message}');
    }
  }

  // ============================================================
  // SET ACTIVE
  // Mengaktifkan atau menonaktifkan kelas.
  // ============================================================

  Future<void> setActive({required String id, required bool aktif}) async {
    try {
      await _supabase
          .from('kelas_pengajaran')
          .update({
            'aktif': aktif,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal ${aktif ? 'mengaktifkan' : 'menonaktifkan'} kelas: '
        '${e.message}',
      );
    }
  }

  // ============================================================
  // DELETE
  // Kelas tidak boleh dihapus jika masih digunakan.
  // ============================================================

  Future<void> delete(String id) async {
    try {
      // Periksa apakah masih ada santri yang terdaftar.
      final pendaftaran = await _supabase
          .from('santri_programs')
          .select('id')
          .eq('kelas_pengajaran_id', id)
          .limit(1);

      if ((pendaftaran as List).isNotEmpty) {
        throw Exception(
          'Kelas tidak dapat dihapus karena masih memiliki santri. '
          'Pindahkan santri ke kelas lain terlebih dahulu.',
        );
      }

      // Periksa apakah kelas tercatat dalam riwayat perpindahan.
      final riwayat = await _supabase
          .from('riwayat_kelas_santri')
          .select('id')
          .or('kelas_asal_id.eq.$id,kelas_tujuan_id.eq.$id')
          .limit(1);

      if ((riwayat as List).isNotEmpty) {
        throw Exception(
          'Kelas tidak dapat dihapus karena sudah tercatat '
          'dalam riwayat perpindahan santri.',
        );
      }

      await _supabase.from('kelas_pengajaran').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception(
          'Kelas tidak dapat dihapus karena masih digunakan '
          'oleh data pendaftaran atau riwayat akademik.',
        );
      }

      throw Exception('Gagal menghapus kelas: ${e.message}');
    }
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  List<KelasPengajaranModel> _mapList(dynamic response) {
    return (response as List)
        .map(
          (row) => KelasPengajaranModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  /// Mengambil kelas pengajaran milik suatu lembaga.
  Future<List<KelasPengajaranModel>> getByLembaga(String lembagaId) async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select(_selectQuery)
          .eq('lembaga_id', lembagaId)
          .order('nama_kelas');

      return (response as List)
          .map(
            (item) =>
                KelasPengajaranModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil kelas pengajaran lembaga: $e');
    }
  }
}
