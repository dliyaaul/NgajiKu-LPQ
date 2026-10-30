import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/santri_program/santri_program_model.dart';

class SantriProgramService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // RELATIONAL SELECT
  // ============================================================

  String get _relationalSelect => '''
  *,
  santri:profiles!santri_programs_santri_id_fkey(*),
  pengajar:profiles!santri_programs_pengajar_id_fkey(id,username,role),
  program:programs!santri_programs_program_id_fkey(*),
  kelas_type:kelas_types!santri_programs_kelas_type_id_fkey(*),
  kelas_pengajaran:kelas_pengajaran!santri_programs_kelas_pengajaran_fk(
    *,
    pengajar:profiles!kelas_pengajaran_pengajar_id_fkey(id,username)
  ),
  lembaga:lembaga!santri_programs_lembaga_id_fkey(*)
''';

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<SantriProgramModel>> getAll() async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data santri program: $e');
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<SantriProgramModel?> getById(String id) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return SantriProgramModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal mengambil detail santri program: $e');
    }
  }

  // ============================================================
  // GET BY SANTRI
  // ============================================================

  Future<List<SantriProgramModel>> getBySantri(String santriId) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('santri_id', santriId)
          .order('created_at', ascending: false);

      final result = (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil program santri: $e');
    }
  }

  // ============================================================
  // GET BY PENGAJAR
  // ============================================================

  Future<List<SantriProgramModel>> getByPengajar(String pengajarId) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('pengajar_id', pengajarId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil program pengajar: $e');
    }
  }

  // ============================================================
  // GET BY PROGRAM
  // ============================================================

  Future<List<SantriProgramModel>> getByProgram(String programId) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('program_id', programId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data berdasarkan program: $e');
    }
  }

  // ============================================================
  // GET BY PROGRAM + KELAS PENGAJARAN
  // ============================================================

  Future<List<SantriProgramModel>> getByProgramAndKelasPengajaran({
    required String programId,
    required String kelasPengajaranId,
  }) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil data santri berdasarkan kelas pengajaran: $e',
      );
    }
  }

  // ============================================================
  // GET BY KELAS TYPE
  // ============================================================

  Future<List<SantriProgramModel>> getByKelasType(String kelasTypeId) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('kelas_type_id', kelasTypeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data berdasarkan tipe kelas: $e');
    }
  }

  // ============================================================
  // GET BY PROGRAM + KELAS TYPE
  // ============================================================

  Future<List<SantriProgramModel>> getByProgramAndKelas({
    required String programId,
    required String kelasTypeId,
  }) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .select(_relationalSelect)
          .eq('program_id', programId)
          .eq('kelas_type_id', kelasTypeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data program dan tipe kelas: $e');
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<SantriProgramModel> create(SantriProgramModel data) async {
    try {
      final response = await _supabase
          .from('santri_programs')
          .insert({
            'santri_id': data.santriId,
            'program_id': data.programId,
            'kelas_type_id': data.kelasTypeId,
            'kelas_pengajaran_id': data.kelasPengajaranId,
            'pengajar_id': data.pengajarId,
            'lembaga_id': data.lembagaId,
            'default_pbm': data.defaultPbm,
          })
          .select(_relationalSelect)
          .single();

      return SantriProgramModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      // PostgreSQL 23505 = unique_violation.
      if (e.code == '23505') {
        throw Exception(
          'Santri ini sudah terdaftar pada program tersebut. '
          'Silakan periksa daftar program santri atau edit '
          'pendaftaran yang sudah ada.',
        );
      }

      throw Exception(
        'Gagal menambahkan program santri. '
        'Silakan coba kembali.',
      );
    } catch (e) {
      throw Exception('Gagal menambahkan program santri: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<SantriProgramModel> update(SantriProgramModel data) async {
    try {
      // Ambil relasi saat ini agar form versi lama yang belum mengirim
      // kelasPengajaranId tidak mengosongkan kelas secara tidak sengaja.
      final current = await _supabase
          .from('santri_programs')
          .select('program_id, kelas_type_id, lembaga_id, kelas_pengajaran_id')
          .eq('id', data.id)
          .maybeSingle();

      if (current == null) {
        throw Exception('Pendaftaran program santri tidak ditemukan.');
      }

      final currentClassId = current['kelas_pengajaran_id']?.toString();
      final scopeChanged =
          current['program_id'] != data.programId ||
          current['kelas_type_id'] != data.kelasTypeId ||
          current['lembaga_id'] != data.lembagaId;

      if (currentClassId != null &&
          data.kelasPengajaranId == null &&
          scopeChanged) {
        throw Exception(
          'Program, jenis kelas, atau lembaga berubah. Pilih kelas pengajaran '
          'yang sesuai terlebih dahulu agar relasi kelas tidak menjadi keliru.',
        );
      }

      final payload = <String, dynamic>{
        'santri_id': data.santriId,
        'program_id': data.programId,
        'kelas_type_id': data.kelasTypeId,
        'pengajar_id': data.pengajarId,
        'lembaga_id': data.lembagaId,
        'default_pbm': data.defaultPbm,
      };

      // Hanya ubah relasi kelas jika caller memang mengirimkan nilai.
      // Pemilihan kelas pada form akan diintegrasikan pada tahap UI berikutnya.
      if (data.kelasPengajaranId != null) {
        payload['kelas_pengajaran_id'] = data.kelasPengajaranId;
      }

      final response = await _supabase
          .from('santri_programs')
          .update(payload)
          .eq('id', data.id)
          .select(_relationalSelect)
          .single();

      return SantriProgramModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal memperbarui program santri: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(String id) async {
    try {
      await _supabase.from('santri_programs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus program santri: $e');
    }
  }
}
