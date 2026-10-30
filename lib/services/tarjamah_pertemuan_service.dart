import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_pertemuan_model.dart';
import 'package:ptl_mobile/models/pengajar_program/pengajar_program_model.dart';

class TarjamahPertemuanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _table = 'tarjamah_pertemuan';

  String? get currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  // RELATIONAL SELECT

  String get _relationalSelect => '''
    *,
    pengajar:profiles!tarjamah_pertemuan_pengajar_fkey(
      id,
      username
    ),
    pengajar_pengganti:pengajar_pengganti!tarjamah_pertemuan_pengajar_pengganti_id_fkey(
      id,
      nama,
      no_hp,
      aktif
    )
  ''';

  // GET ALL PERTEMUAN

  Future<List<TarjamahPertemuanModel>> getAllPertemuan() async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (json) => TarjamahPertemuanModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tarjamah: $e');
    }
  }

  // GET PERTEMUAN BY PROGRAM / KELAS

  Future<List<TarjamahPertemuanModel>> getPertemuanByProgram(
    String programId, {
    String? kelasPengajaranId,
  }) async {
    try {
      var query = _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('program_id', programId);

      // Jika kelas dipilih, filter pertemuan berdasarkan kelas.
      if (kelasPengajaranId != null && kelasPengajaranId.trim().isNotEmpty) {
        query = query.eq('kelas_pengajaran_id', kelasPengajaranId);
      }

      final response = await query.order('tanggal', ascending: false);

      return (response as List)
          .map(
            (json) => TarjamahPertemuanModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil pertemuan Tarjamah berdasarkan program/kelas: $e',
      );
    }
  }

  // GET KELAS PENGAJARAN BY PROGRAM

  Future<List<Map<String, dynamic>>> getKelasPengajaranByProgram(
    String programId,
  ) async {
    try {
      final response = await _supabase
          .from('kelas_pengajaran')
          .select('''
            id,
            program_id,
            kelas_type_id,
            nama_kelas,
            pengajar_id,
            lembaga_id,
            aktif,
            kelas_types(
              id,
              nama
            )
          ''')
          .eq('program_id', programId)
          .eq('aktif', true)
          .order('nama_kelas', ascending: true);

      return (response as List)
          .map((json) => Map<String, dynamic>.from(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil kelas pengajaran Tarjamah: $e');
    }
  }

  // GET PERTEMUAN BY ID

  Future<TarjamahPertemuanModel> getPertemuanById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('id', id)
          .single();

      return TarjamahPertemuanModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal mengambil detail pertemuan Tarjamah: $e');
    }
  }

  // GET PERTEMUAN BY DATE RANGE

  Future<List<TarjamahPertemuanModel>> getPertemuanByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .gte('tanggal', _formatDate(startDate))
          .lte('tanggal', _formatDate(endDate))
          .order('tanggal', ascending: false);

      return (response as List)
          .map(
            (json) => TarjamahPertemuanModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil pertemuan Tarjamah berdasarkan tanggal: $e',
      );
    }
  }

  // GET PERTEMUAN BY PENGAJAR

  Future<List<TarjamahPertemuanModel>> getPertemuanByPengajar(
    String pengajarId,
  ) async {
    try {
      final pengajarResponse = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('pengajar_id', pengajarId)
          .order('tanggal', ascending: false);

      final penggantiResponse = await _supabase
          .from(_table)
          .select(_relationalSelect)
          .eq('pengajar_pengganti_id', pengajarId)
          .order('tanggal', ascending: false);

      final combined = [
        ...(pengajarResponse as List),
        ...(penggantiResponse as List),
      ];

      final result = combined
          .map(
            (json) => TarjamahPertemuanModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();

      final unique = <String, TarjamahPertemuanModel>{};

      for (final item in result) {
        unique[item.id] = item;
      }

      final finalResult = unique.values.toList();

      finalResult.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      return finalResult;
    } catch (e) {
      throw Exception(
        'Gagal mengambil pertemuan Tarjamah berdasarkan pengajar: $e',
      );
    }
  }

  // GET PENGAJAR BY PROGRAM

  Future<List<PengajarProgramModel>> getPengajarByProgram(
    String programId,
  ) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            *,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username,
              email,
              no_hp,
              alamat,
              avatar_url,
              role
            ),
            program:programs(
              id,
              nama,
              deskripsi
            )
          ''')
          .eq('program_id', programId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) =>
                PengajarProgramModel.fromMap(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception(
        'Gagal mengambil pengajar berdasarkan program Tarjamah: $e',
      );
    }
  }

  // CREATE PERTEMUAN

  Future<TarjamahPertemuanModel> createPertemuan(
    TarjamahPertemuanModel model,
  ) async {
    try {
      final data = model.toInsertJson();

      data['created_by'] ??= currentUserId;

      // Waktu pembuatan dari perangkat.
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect)
          .single();

      return TarjamahPertemuanModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal menambahkan pertemuan Tarjamah: $e');
    }
  }

  // CREATE MANY PERTEMUAN

  Future<List<TarjamahPertemuanModel>> createManyPertemuan(
    List<TarjamahPertemuanModel> models,
  ) async {
    if (models.isEmpty) {
      return [];
    }

    try {
      final data = models.map((model) {
        final json = model.toInsertJson();

        json['created_by'] ??= currentUserId;
        json['created_at'] = DateTime.now().toIso8601String();

        return json;
      }).toList();

      final response = await _supabase
          .from(_table)
          .insert(data)
          .select(_relationalSelect);

      return (response as List)
          .map(
            (json) => TarjamahPertemuanModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal menambahkan beberapa pertemuan Tarjamah: $e');
    }
  }

  // UPDATE PERTEMUAN

  Future<TarjamahPertemuanModel> updatePertemuan(
    TarjamahPertemuanModel model,
  ) async {
    try {
      if (!model.canEdit) {
        throw Exception('Pertemuan sudah melewati batas waktu edit 24 jam.');
      }

      final response = await _supabase
          .from(_table)
          .update(model.toUpdateJson())
          .eq('id', model.id)
          .select(_relationalSelect)
          .single();

      return TarjamahPertemuanModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Gagal memperbarui pertemuan Tarjamah: $e');
    }
  }

  // DELETE PERTEMUAN

  Future<void> deletePertemuan(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus pertemuan Tarjamah: $e');
    }
  }

  // FORMAT DATE

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
