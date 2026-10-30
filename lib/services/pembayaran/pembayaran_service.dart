import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/pembayaran/pembayaran_rekening_model.dart';

class PembayaranService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PembayaranRekeningModel>> getRekeningAktif() async {
    final response = await _supabase
        .from('pembayaran_rekening')
        .select('id, nama_bank, nomor_rekening, nama_pemilik, keterangan')
        .eq('aktif', true)
        .order('urutan', ascending: true);

    return (response as List)
        .map(
          (json) => PembayaranRekeningModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<void> ajukanPembayaran({
    required String tagihanId,
    required String rekeningTujuanId,
    required DateTime tanggalTransfer,
    required double nominalTransfer,
    required String namaPengirim,
    required String rekeningPengirim,
    required String catatan,
    required Uint8List bytes,
    required String namaFile,
    required String mimeType,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Sesi login berakhir. Silakan login kembali.');
    }

    if (bytes.isEmpty) {
      throw Exception('File bukti transfer kosong.');
    }

    if (nominalTransfer <= 0) {
      throw Exception('Nominal pembayaran tidak valid.');
    }

    final extension = _extensionFile(namaFile);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    // Struktur folder sesuai policy Storage:
    // USER_AUTH_ID/nama_file.ext
    final storagePath = '${user.id}/$timestamp.$extension';

    // Upload ke bucket privat.
    await _supabase.storage
        .from('bukti-transfer')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    final nomorPembayaran = 'BYR-$timestamp';

    // Status awal harus menunggu_verifikasi.
    // Trigger database akan mengubah status tagihan dan mencatat log.
    await _supabase.from('pembayaran').insert({
      'nomor_pembayaran': nomorPembayaran,
      'tagihan_id': tagihanId,
      'rekening_tujuan_id': rekeningTujuanId,
      'tanggal_transfer': _formatTanggalDatabase(tanggalTransfer),
      'nominal_transfer': nominalTransfer,
      'nama_pengirim': _nullable(namaPengirim),
      'rekening_pengirim': _nullable(rekeningPengirim),
      'bukti_transfer': storagePath,
      'catatan': _nullable(catatan),
      'status': 'menunggu_verifikasi',
      'created_by': user.id,
    });
  }

  String _extensionFile(String filename) {
    final index = filename.lastIndexOf('.');
    if (index < 0 || index == filename.length - 1) {
      throw Exception('Format file tidak dikenali.');
    }
    return filename.substring(index + 1).toLowerCase();
  }

  String _formatTanggalDatabase(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
