import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/pembayaran/verifikasi_pembayaran_model.dart';

class VerifikasiPembayaranService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VerifikasiPembayaranModel>> getMenungguVerifikasi() async {
    final data = await _supabase
        .from('pembayaran')
        .select()
        .eq('status', 'menunggu_verifikasi')
        .order('created_at', ascending: true);

    final hasil = <VerifikasiPembayaranModel>[];

    for (final row in data) {
      final pembayaran = Map<String, dynamic>.from(row);

      final tagihanData = await _supabase
          .from('tagihan')
          .select('id, nomor_tagihan, total, periode_mulai, periode_selesai')
          .eq('id', pembayaran['tagihan_id'])
          .single();

      final rekeningData = await _supabase
          .from('pembayaran_rekening')
          .select('id, nama_bank, nomor_rekening, nama_pemilik')
          .eq('id', pembayaran['rekening_tujuan_id'])
          .single();

      pembayaran['tagihan'] = Map<String, dynamic>.from(tagihanData);
      pembayaran['rekening'] = Map<String, dynamic>.from(rekeningData);

      hasil.add(VerifikasiPembayaranModel.fromJson(pembayaran));
    }

    return hasil;
  }

  Future<String> getUrlBuktiTransfer(String storagePath) async {
    return _supabase.storage
        .from('bukti-transfer')
        .createSignedUrl(storagePath, 300);
  }

  Future<void> verifikasi({
    required String pembayaranId,
    required String statusBaru,
    String? catatan,
  }) async {
    if (statusBaru != 'diterima' && statusBaru != 'ditolak') {
      throw ArgumentError('Status verifikasi tidak valid.');
    }

    if (statusBaru == 'ditolak' &&
        (catatan == null || catatan.trim().isEmpty)) {
      throw ArgumentError('Alasan penolakan wajib diisi.');
    }

    await _supabase.rpc(
      'admin_verifikasi_pembayaran',
      params: {
        'p_pembayaran_id': pembayaranId,
        'p_status_baru': statusBaru,
        'p_catatan': catatan?.trim(),
      },
    );
  }
}
