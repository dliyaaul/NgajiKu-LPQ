import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/program/program_model.dart';

class ProgramService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mengambil semua program
  Future<List<ProgramModel>> getAllPrograms() async {
    try {
      final response = await _supabase.from('programs').select().order('nama');

      return (response as List)
          .map((item) => ProgramModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data program: $e');
    }
  }

  Future<Map<String, dynamic>?> getProgramBbaq() async {
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .ilike('nama', '%BBAQ%')
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Gagal mengambil program BBAQ: $e');
    }
  }

  /// Mengambil program berdasarkan ID
  Future<ProgramModel?> getProgramById(String id) async {
    try {
      final response = await _supabase
          .from('programs')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ProgramModel.fromMap(response);
    } catch (e) {
      throw Exception('Gagal mengambil program: $e');
    }
  }

  /// Menambahkan program
  Future<ProgramModel> createProgram({
    required String nama,
    String? deskripsi,
  }) async {
    try {
      final response = await _supabase
          .from('programs')
          .insert({'nama': nama, 'deskripsi': deskripsi})
          .select()
          .single();

      return ProgramModel.fromMap(response);
    } catch (e) {
      throw Exception('Gagal menambahkan program: $e');
    }
  }

  /// Update program
  Future<ProgramModel> updateProgram(ProgramModel program) async {
    try {
      final response = await _supabase
          .from('programs')
          .update({'nama': program.nama, 'deskripsi': program.deskripsi})
          .eq('id', program.id)
          .select()
          .single();

      return ProgramModel.fromMap(response);
    } catch (e) {
      throw Exception('Gagal memperbarui program: $e');
    }
  }

  /// Hapus program
  Future<void> deleteProgram(String id) async {
    try {
      await _supabase.from('programs').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus program: $e');
    }
  }
}
