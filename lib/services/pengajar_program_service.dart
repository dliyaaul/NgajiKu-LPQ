import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pengajar_program/pengajar_program_model.dart';

class PengajarProgramService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // GET SEMUA RELASI PENGAJAR - PROGRAM
  // ============================================================

  Future<List<PengajarProgramModel>> getAll() async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            id,
            pengajar_id,
            program_id,
            created_at,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username
            ),
            program:programs!pengajar_programs_program_id_fkey(
              id,
              nama,
              deskripsi
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                PengajarProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pengajar-program: $e');
    }
  }

  // ============================================================
  // GET PROGRAM YANG DIAJAR OLEH PENGAJAR
  // ============================================================

  Future<List<PengajarProgramModel>> getByPengajar(String pengajarId) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            id,
            pengajar_id,
            program_id,
            created_at,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username
            ),
            program:programs!pengajar_programs_program_id_fkey(
              id,
              nama,
              deskripsi
            )
          ''')
          .eq('pengajar_id', pengajarId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) =>
                PengajarProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil program pengajar: $e');
    }
  }

  // ============================================================
  // GET PENGAJAR BERDASARKAN PROGRAM
  // ============================================================

  Future<List<Map<String, dynamic>>> getPengajarByProgram(
    String programId,
  ) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            pengajar_id,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username,
              role
            )
          ''')
          .eq('program_id', programId)
          .order('created_at', ascending: true);

      final result = <Map<String, dynamic>>[];

      for (final raw in response) {
        final item = Map<String, dynamic>.from(raw);

        final pengajar = item['pengajar'];

        if (pengajar is Map) {
          result.add(Map<String, dynamic>.from(pengajar));
        }
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil daftar pengajar program: $e');
    }
  }

  // ============================================================
  // CEK APAKAH PENGAJAR SUDAH TERDAFTAR PADA PROGRAM
  // ============================================================

  Future<bool> exists({
    required String pengajarId,
    required String programId,
  }) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('id')
          .eq('pengajar_id', pengajarId)
          .eq('program_id', programId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Gagal mengecek relasi pengajar-program: $e');
    }
  }

  // ============================================================
  // TAMBAH PROGRAM UNTUK PENGAJAR
  // ============================================================

  Future<PengajarProgramModel> create({
    required String pengajarId,
    required String programId,
  }) async {
    try {
      final alreadyExists = await exists(
        pengajarId: pengajarId,
        programId: programId,
      );

      if (alreadyExists) {
        throw Exception('Pengajar sudah terdaftar pada program tersebut.');
      }

      final response = await _supabase
          .from('pengajar_programs')
          .insert({'pengajar_id': pengajarId, 'program_id': programId})
          .select('''
            id,
            pengajar_id,
            program_id,
            created_at,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username
            ),
            program:programs!pengajar_programs_program_id_fkey(
              id,
              nama,
              deskripsi
            )
          ''')
          .single();

      return PengajarProgramModel.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Gagal menambahkan program untuk pengajar: $e');
    }
  }

  // ============================================================
  // TAMBAH BEBERAPA PROGRAM SEKALIGUS
  // ============================================================

  Future<void> createMany({
    required String pengajarId,
    required List<String> programIds,
  }) async {
    if (programIds.isEmpty) {
      return;
    }

    try {
      final uniqueProgramIds = programIds.toSet().toList();

      final data = uniqueProgramIds
          .map(
            (programId) => {'pengajar_id': pengajarId, 'program_id': programId},
          )
          .toList();

      await _supabase
          .from('pengajar_programs')
          .upsert(data, onConflict: 'pengajar_id,program_id');
    } catch (e) {
      throw Exception('Gagal menambahkan program pengajar: $e');
    }
  }

  // ============================================================
  // HAPUS RELASI PENGAJAR - PROGRAM
  // ============================================================

  Future<void> delete(String id) async {
    try {
      await _supabase.from('pengajar_programs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus program dari pengajar: $e');
    }
  }

  // ============================================================
  // HAPUS BERDASARKAN PENGAJAR + PROGRAM
  // ============================================================

  Future<void> deleteByPengajarAndProgram({
    required String pengajarId,
    required String programId,
  }) async {
    try {
      await _supabase
          .from('pengajar_programs')
          .delete()
          .eq('pengajar_id', pengajarId)
          .eq('program_id', programId);
    } catch (e) {
      throw Exception('Gagal menghapus relasi pengajar-program: $e');
    }
  }

  // ============================================================
  // UPDATE PROGRAM PENGAJAR
  //
  // Digunakan ketika UI memberikan daftar program terbaru.
  // Program lama yang tidak dipilih akan dihapus,
  // program baru akan ditambahkan.
  // ============================================================

  Future<void> syncPrograms({
    required String pengajarId,
    required List<String> programIds,
  }) async {
    try {
      final currentResponse = await _supabase
          .from('pengajar_programs')
          .select('program_id')
          .eq('pengajar_id', pengajarId);

      final currentProgramIds = (currentResponse as List)
          .map((item) => item['program_id']?.toString())
          .whereType<String>()
          .toSet();

      final newProgramIds = programIds.toSet();

      final toAdd = newProgramIds.difference(currentProgramIds);

      final toDelete = currentProgramIds.difference(newProgramIds);

      // Tambahkan program baru
      if (toAdd.isNotEmpty) {
        final insertData = toAdd
            .map(
              (programId) => {
                'pengajar_id': pengajarId,
                'program_id': programId,
              },
            )
            .toList();

        await _supabase.from('pengajar_programs').insert(insertData);
      }

      // Hapus program yang sudah tidak dipilih
      if (toDelete.isNotEmpty) {
        await _supabase
            .from('pengajar_programs')
            .delete()
            .eq('pengajar_id', pengajarId)
            .inFilter('program_id', toDelete.toList());
      }
    } catch (e) {
      throw Exception('Gagal memperbarui program pengajar: $e');
    }
  }
}
