import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/pembayaran/tagihan_model.dart';

class TagihanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _selectTagihan = '''
  *,
  tagihan_item(*),
  santri_programs(
    santri_id,
    program_id,
    profiles!santri_programs_santri_id_fkey(username),
    programs(nama)
  )
''';

  /// Mengambil daftar tagihan yang boleh diakses pengguna login.
  /// Akses tetap mengikuti kebijakan RLS Supabase.
  Future<List<TagihanModel>> getTagihanSaya() async {
    final response = await _supabase
        .from('tagihan')
        .select(_selectTagihan)
        .order('tanggal_tagihan', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) =>
              TagihanModel.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  /// Mengambil detail satu tagihan.
  Future<TagihanModel> getDetailTagihan(String tagihanId) async {
    final response = await _supabase
        .from('tagihan')
        .select(_selectTagihan)
        .eq('id', tagihanId)
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Tagihan tidak ditemukan atau kamu tidak memiliki akses.',
      );
    }

    return TagihanModel.fromJson(Map<String, dynamic>.from(response));
  }
}
