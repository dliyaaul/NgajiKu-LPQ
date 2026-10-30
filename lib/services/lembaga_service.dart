import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lembaga/lembaga_model.dart';
import '../models/santri_program/santri_program_model.dart';

class LembagaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Semua lembaga.
  Future<List<LembagaModel>> getAllLembaga() async {
    try {
      final response = await _supabase
          .from('lembaga')
          .select()
          .order('nama_lembaga');

      return (response as List)
          .map(
            (item) => LembagaModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data lembaga: $e');
    }
  }

  /// Lembaga berdasarkan ID.
  Future<LembagaModel?> getLembagaById(String id) async {
    try {
      final response = await _supabase
          .from('lembaga')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return LembagaModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal mengambil lembaga: $e');
    }
  }

  /// Tambah lembaga.
  ///
  /// Pengajar tidak ditetapkan di tabel lembaga. Untuk kelas lembaga,
  /// pengajar dikelola melalui `kelas_pengajaran.pengajar_id`.
  ///
  /// Parameter `pengajarId` tetap dipertahankan sementara agar pemanggil
  /// lama tidak langsung mengalami error kompilasi, tetapi tidak disimpan.
  Future<LembagaModel> createLembaga({
    required String namaLembaga,
    required String pbmType,
    String? alamat,
    String? programId,
    String? pengajarId,
  }) async {
    try {
      final response = await _supabase
          .from('lembaga')
          .insert({
            'nama_lembaga': namaLembaga,
            'pbm_type': pbmType,
            'alamat': alamat,
            'program_id': programId,
          })
          .select()
          .single();

      return LembagaModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal menambahkan lembaga: $e');
    }
  }

  /// Update data lembaga tanpa mengubah kolom legacy `pengajar_id`.
  ///
  /// Pengajar kelas lembaga bersumber dari `kelas_pengajaran.pengajar_id`.
  Future<LembagaModel> updateLembaga(LembagaModel lembaga) async {
    try {
      final response = await _supabase
          .from('lembaga')
          .update({
            'nama_lembaga': lembaga.namaLembaga,
            'pbm_type': lembaga.pbmType,
            'alamat': lembaga.alamat,
            'program_id': lembaga.programId,
          })
          .eq('id', lembaga.id)
          .select()
          .single();

      return LembagaModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal memperbarui lembaga: $e');
    }
  }

  /// Hapus lembaga.
  Future<void> deleteLembaga(String id) async {
    try {
      await _supabase.from('lembaga').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus lembaga: $e');
    }
  }

  // ============================================================
  // GET SANTRI BERDASARKAN LEMBAGA
  // ============================================================

  /// Mengambil pendaftaran santri beserta data relasi kelas pengajaran.
  ///
  /// `kelas_pengajaran` menjadi sumber utama nama kelas dan pengajar
  /// untuk pendaftaran yang terkait dengan lembaga.
  Future<List<SantriProgramModel>> getSantriByLembaga(
    String lembagaId,
  ) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select('''
            *,
            santri:profiles!santri_programs_santri_id_fkey(*),
            pengajar:profiles!santri_programs_pengajar_id_fkey(*),
            program:programs(*),
            kelas_type:kelas_types(*),
            kelas_pengajaran(*),
            lembaga:lembaga!santri_programs_lembaga_id_fkey(*)
          ''')
          .eq('lembaga_id', lembagaId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) => SantriProgramModel.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data santri lembaga: $e');
    }
  }
}
