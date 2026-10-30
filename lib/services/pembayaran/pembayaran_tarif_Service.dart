import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/pembayaran/pembayaran_tarif_model.dart';

class PembayaranTarifService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String regulerId = '12539687-7c5a-4a53-8064-26673ed22c31';

  static const String privatId = '1f1e32c6-5d16-4fec-9f7e-80e48a555bd8';

  static const String lembagaId = '501fd6e7-3560-4c8e-b89a-58e3d62d8d0f';

  Future<List<PembayaranTarifModel>> getAll({bool hanyaAktif = false}) async {
    var query = _supabase.from('pembayaran_tarif').select();

    if (hanyaAktif) {
      query = query.eq('aktif', true);
    }

    final data = await query.order('created_at', ascending: false);

    return data
        .map(
          (row) =>
              PembayaranTarifModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<PembayaranTarifModel> getById(String id) async {
    final data = await _supabase
        .from('pembayaran_tarif')
        .select()
        .eq('id', id)
        .single();

    return PembayaranTarifModel.fromJson(data);
  }

  Future<void> create(PembayaranTarifModel tarif) async {
    _validasi(tarif);

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    final payload = tarif.toJson()..['created_by'] = user.id;

    await _supabase.from('pembayaran_tarif').insert(payload);
  }

  Future<void> update(String id, PembayaranTarifModel tarif) async {
    _validasi(tarif);

    await _supabase
        .from('pembayaran_tarif')
        .update(tarif.toJson())
        .eq('id', id);
  }

  Future<void> setAktif({required String id, required bool aktif}) async {
    await _supabase
        .from('pembayaran_tarif')
        .update({
          'aktif': aktif,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  void _validasi(PembayaranTarifModel tarif) {
    if (tarif.namaTarif.trim().isEmpty) {
      throw ArgumentError('Nama tarif wajib diisi.');
    }

    if (tarif.nominal <= 0) {
      throw ArgumentError('Nominal tarif harus lebih besar dari nol.');
    }

    if (tarif.berlakuSampai != null &&
        tarif.berlakuSampai!.isBefore(tarif.berlakuMulai)) {
      throw ArgumentError(
        'Tanggal akhir tarif tidak boleh sebelum tanggal mulai.',
      );
    }

    // REGULER: tarif umum untuk semua program.
    if (tarif.kelasTypeId == regulerId) {
      if (tarif.programId != null ||
          tarif.santriProgramId != null ||
          tarif.lembagaId != null) {
        throw ArgumentError(
          'Tarif Reguler umum tidak boleh terikat pada '
          'program, santri, atau lembaga tertentu.',
        );
      }

      if (tarif.satuan != 'bulan') {
        throw ArgumentError('Tarif Reguler harus menggunakan satuan bulan.');
      }

      return;
    }

    // PRIVAT: tarif khusus untuk satu santri-program.
    if (tarif.kelasTypeId == privatId) {
      if (tarif.santriProgramId == null) {
        throw ArgumentError('Santri-program wajib dipilih untuk tarif Privat.');
      }

      if (tarif.programId != null || tarif.lembagaId != null) {
        throw ArgumentError(
          'Tarif Privat tidak boleh memiliki target program '
          'atau lembaga secara terpisah.',
        );
      }

      if (tarif.satuan != 'pertemuan') {
        throw ArgumentError('Tarif Privat harus menggunakan satuan pertemuan.');
      }

      return;
    }

    // LEMBAGA: tarif khusus untuk lembaga dan program.
    if (tarif.kelasTypeId == lembagaId) {
      if (tarif.lembagaId == null || tarif.programId == null) {
        throw ArgumentError(
          'Lembaga dan program wajib dipilih untuk tarif Lembaga.',
        );
      }

      if (tarif.santriProgramId != null) {
        throw ArgumentError(
          'Tarif Lembaga tidak boleh terikat pada santri tertentu.',
        );
      }

      if (tarif.satuan != 'pertemuan') {
        throw ArgumentError(
          'Tarif Lembaga harus menggunakan satuan pertemuan.',
        );
      }

      return;
    }

    throw ArgumentError('Jenis kelas tidak valid.');
  }
}
