import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/kelas/riwayat_kelas_santri_model.dart';

class RiwayatKelasSantriService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<RiwayatKelasSantriModel>> getBySantriProgram(
    String santriProgramId,
  ) async {
    try {
      final response = await _supabase
          .from('riwayat_kelas_santri')
          .select('''
            id,
            santri_program_id,
            kelas_asal_id,
            kelas_tujuan_id,
            berlaku_mulai,
            created_at,
            alasan,
            kelas_asal:kelas_pengajaran!riwayat_kelas_santri_kelas_asal_id_fkey(
              nama_kelas
            ),
            kelas_tujuan:kelas_pengajaran!riwayat_kelas_santri_kelas_tujuan_id_fkey(
              nama_kelas
            )
          ''')
          .eq('santri_program_id', santriProgramId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (row) =>
                RiwayatKelasSantriModel.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat riwayat kelas (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Gagal memuat riwayat kelas: $e');
    }
  }
}
