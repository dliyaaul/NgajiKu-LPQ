import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ptl_mobile/models/absensi_tahfidz/absensi_tahfidz_model.dart';
import 'package:ptl_mobile/models/santri_program/santri_program_model.dart';
import 'package:ptl_mobile/models/absensi_tahfidz/tahfidz_pertemuan_model.dart';

class AbsensiTahfidzService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _absensiTable = 'absensi_tahfidz';
  static const String _santriProgramTable = 'santri_programs';

  // ================================================================
  // CURRENT USER
  // ================================================================

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ================================================================
  // GET SANTRI TAHSIN / TAHFIDZ
  // ================================================================

  Future<List<SantriProgramModel>> getSantriTahfidz({
    required String programId,
    required String kelasPengajaranId,
  }) async {
    try {
      final response = await _supabase
          .from(_santriProgramTable)
          .select('''
          id,
          santri_id,
          program_id,
          kelas_type_id,
          kelas_pengajaran_id,
          pengajar_id,
          default_pbm,
          lembaga_id,
          created_at,

          santri:santri_id(
            id,
            username,
            email,
            nik,
            alamat,
            no_hp,
            role,
            avatar_url,
            lembaga_id,
            created_at
          ),

          program:program_id(
            id,
            nama
          ),

          kelas_type:kelas_type_id(
            id,
            nama
          ),

          pengajar:pengajar_id(
            id,
            username,
            email,
            nik,
            alamat,
            no_hp,
            role,
            avatar_url,
            lembaga_id,
            created_at
          ),

          kelas_pengajaran:kelas_pengajaran_id(
            id,
            nama
          ),

          lembaga:lembaga_id(
            id,
            nama_lembaga,
            pbm_type,
            alamat
          )
        ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (item) =>
                SantriProgramModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data santri Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data santri Tahfidz: $e');
    }
  }

  Future<TahfidzPertemuanModel?> getPertemuanById(String pertemuanId) async {
    if (pertemuanId.isEmpty) {
      throw Exception('ID pertemuan Tahfidz tidak valid.');
    }

    try {
      final response = await _supabase
          .from('tahfidz_pertemuan')
          .select('''
          *,
          pengajar:profiles!tahfidz_pertemuan_pengajar_id_fkey(
            id,
            username
          ),
          pengganti_pengajar:pengajar_pengganti!tahfidz_pertemuan_pengganti_pengajar_id_fkey(
            id,
            nama,
            aktif
          ),
          program:programs(
            id,
            nama
          )
        ''')
          .eq('id', pertemuanId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return TahfidzPertemuanModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tahfidz: $e');
    }
  }

  // ================================================================
  // GET PENGAJAR BERDASARKAN PROGRAM
  // ================================================================

  Future<List<Map<String, dynamic>>> getPengajarByProgram(
    String programId,
  ) async {
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
              username,
              email,
              no_hp,
              avatar_url
            )
          ''')
          .eq('program_id', programId)
          .order('created_at', ascending: true);

      final result = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final item in response as List) {
        final map = Map<String, dynamic>.from(item);

        final pengajarId = map['pengajar_id']?.toString();

        if (pengajarId == null || pengajarId.isEmpty) {
          continue;
        }

        if (seen.contains(pengajarId)) {
          continue;
        }

        seen.add(pengajarId);
        result.add(map);
      }

      result.sort((a, b) {
        final pengajarA = a['pengajar'];

        final pengajarB = b['pengajar'];

        final namaA = pengajarA is Map
            ? (pengajarA['username']?.toString() ?? '')
            : '';

        final namaB = pengajarB is Map
            ? (pengajarB['username']?.toString() ?? '')
            : '';

        return namaA.toLowerCase().compareTo(namaB.toLowerCase());
      });

      return result;
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data pengajar Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data pengajar Tahfidz: $e');
    }
  }

  // ================================================================
  // GET ABSENSI BERDASARKAN PERTEMUAN
  // ================================================================

  Future<List<AbsensiTahfidzModel>> getAbsensiByPertemuan(
    String pertemuanId,
  ) async {
    if (pertemuanId.isEmpty) {
      throw Exception('ID pertemuan Tahfidz tidak valid.');
    }

    try {
      final response = await _supabase
          .from(_absensiTable)
          .select('*')
          .eq('tahfidz_pertemuan_id', pertemuanId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (item) =>
                AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // GET CREATED AT PERTEMUAN
  // ================================================================

  Future<DateTime> getPertemuanCreatedAt(String pertemuanId) async {
    if (pertemuanId.isEmpty) {
      throw Exception('ID pertemuan Tahfidz tidak valid.');
    }

    try {
      final response = await _supabase
          .from('tahfidz_pertemuan')
          .select('created_at')
          .eq('id', pertemuanId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Pertemuan Tahfidz tidak ditemukan.');
      }

      final createdAtRaw = response['created_at'];

      if (createdAtRaw == null) {
        throw Exception('Waktu pembuatan pertemuan tidak ditemukan.');
      }

      return DateTime.parse(createdAtRaw.toString()).toLocal();
    } on PostgrestException catch (e) {
      throw Exception(
        'Gagal mengambil waktu pembuatan pertemuan Tahfidz: ${e.message}',
      );
    } catch (e) {
      if (e is Exception) rethrow;

      throw Exception('Gagal mengambil waktu pembuatan pertemuan Tahfidz: $e');
    }
  }

  // ================================================================
  // GET SATU ABSENSI
  // ================================================================

  Future<AbsensiTahfidzModel?> getAbsensiById(String id) async {
    if (id.isEmpty) {
      throw Exception('ID absensi tidak valid.');
    }

    try {
      final response = await _supabase
          .from(_absensiTable)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data absensi: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil data absensi: $e');
    }
  }

  // ================================================================
  // CREATE ABSENSI
  // ================================================================

  Future<AbsensiTahfidzModel> createAbsensi(AbsensiTahfidzModel model) async {
    if (model.tahfidzPertemuanId.isEmpty) {
      throw Exception('Pertemuan Tahfidz belum dipilih.');
    }

    if (model.santriProgramId.isEmpty) {
      throw Exception('Santri program tidak valid.');
    }

    try {
      final data = model.toMap(includeId: false, includeCreatedAt: false);

      data['created_by'] ??= currentUserId;

      final response = await _supabase
          .from(_absensiTable)
          .insert(data)
          .select('*')
          .single();

      return AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal menyimpan absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menyimpan absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // UPSERT SATU ABSENSI
  // ================================================================

  Future<AbsensiTahfidzModel> upsertAbsensi(AbsensiTahfidzModel model) async {
    if (model.tahfidzPertemuanId.isEmpty) {
      throw Exception('Pertemuan Tahfidz belum dipilih.');
    }

    if (model.santriProgramId.isEmpty) {
      throw Exception('Santri program tidak valid.');
    }

    try {
      final data = model.toMap(includeId: false, includeCreatedAt: false);

      data['created_by'] ??= currentUserId;

      final response = await _supabase
          .from(_absensiTable)
          .upsert(data, onConflict: 'tahfidz_pertemuan_id,santri_program_id')
          .select('*')
          .single();

      return AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal menyimpan absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menyimpan absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // UPSERT BANYAK ABSENSI
  // ================================================================

  Future<List<AbsensiTahfidzModel>> upsertManyAbsensi(
    List<AbsensiTahfidzModel> models,
  ) async {
    if (models.isEmpty) {
      return [];
    }

    for (final model in models) {
      if (model.tahfidzPertemuanId.isEmpty) {
        throw Exception('Terdapat absensi tanpa ID pertemuan Tahfidz.');
      }

      if (model.santriProgramId.isEmpty) {
        throw Exception('Terdapat absensi tanpa santri program.');
      }
    }

    // --------------------------------------------------------------
    // VALIDASI BATAS WAKTU 24 JAM
    // --------------------------------------------------------------

    final pertemuanId = models.first.tahfidzPertemuanId;

    final semuaPertemuanSama = models.every(
      (model) => model.tahfidzPertemuanId == pertemuanId,
    );

    if (!semuaPertemuanSama) {
      throw Exception('Data absensi berasal dari pertemuan yang berbeda.');
    }

    final createdAt = await getPertemuanCreatedAt(pertemuanId);

    final batasWaktu = createdAt.add(const Duration(hours: 24));

    if (!DateTime.now().isBefore(batasWaktu)) {
      throw Exception(
        'Masa input absensi telah berakhir. '
        'Absensi hanya dapat diisi atau diubah dalam waktu 24 jam '
        'sejak pertemuan dibuat.',
      );
    }

    try {
      final data = models.map((model) {
        final map = model.toMap(includeId: false, includeCreatedAt: false);

        map['created_by'] ??= currentUserId;

        return map;
      }).toList();

      final response = await _supabase
          .from(_absensiTable)
          .upsert(data, onConflict: 'tahfidz_pertemuan_id,santri_program_id')
          .select('*');

      return (response as List)
          .map(
            (item) =>
                AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal menyimpan absensi Tahfidz: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;

      throw Exception('Gagal menyimpan absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // UPDATE ABSENSI
  // ================================================================

  Future<AbsensiTahfidzModel> updateAbsensi(AbsensiTahfidzModel model) async {
    if (model.id.isEmpty) {
      throw Exception('ID absensi tidak valid.');
    }

    try {
      final data = model.toMap(includeId: false, includeCreatedAt: false);

      final response = await _supabase
          .from(_absensiTable)
          .update(data)
          .eq('id', model.id)
          .select('*')
          .single();

      return AbsensiTahfidzModel.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal memperbarui absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // DELETE ABSENSI
  // ================================================================

  Future<void> deleteAbsensi(String id) async {
    if (id.isEmpty) {
      throw Exception('ID absensi tidak valid.');
    }

    try {
      await _supabase.from(_absensiTable).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghapus absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // DELETE SEMUA ABSENSI DALAM PERTEMUAN
  // ================================================================

  Future<void> deleteAbsensiByPertemuan(String pertemuanId) async {
    if (pertemuanId.isEmpty) {
      throw Exception('ID pertemuan tidak valid.');
    }

    try {
      await _supabase
          .from(_absensiTable)
          .delete()
          .eq('tahfidz_pertemuan_id', pertemuanId);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus absensi pertemuan: ${e.message}');
    } catch (e) {
      throw Exception('Gagal menghapus absensi pertemuan: $e');
    }
  }

  // ================================================================
  // REKAP BULANAN
  // ================================================================
  //
  // Dipertahankan agar halaman rekap lama tidak langsung rusak.
  // Rekap baru sebaiknya nanti mengambil relasi melalui
  // tahfidz_pertemuan.
  //

  Future<List<Map<String, dynamic>>> getRekapBulanan({
    required String programId,
    required DateTime tanggalAwal,
    required DateTime tanggalAkhir,
  }) async {
    try {
      final response = await _supabase
          .from(_absensiTable)
          .select('''
            *,
            santri_program:santri_program_id(
              id,
              santri_id,
              program_id,
              kelas_type_id,
              pengajar_id,
              default_pbm,
              lembaga_id,

              santri:santri_id(
                id,
                username,
                nik
              )
            ),

            pertemuan:tahfidz_pertemuan_id(
              id,
              program_id,
              tanggal,
              pengajar_id,
              pengganti_pengajar_id,
              materi_pembelajaran,
              metode
            )
          ''')
          .gte('tanggal', _formatDate(tanggalAwal))
          .lte('tanggal', _formatDate(tanggalAkhir));

      final result = <Map<String, dynamic>>[];

      for (final item in response as List) {
        final map = Map<String, dynamic>.from(item);

        final pertemuan = map['pertemuan'];

        if (pertemuan is Map) {
          final pertemuanProgramId = pertemuan['program_id']?.toString();

          if (pertemuanProgramId != null && pertemuanProgramId != programId) {
            continue;
          }
        } else {
          continue;
        }

        result.add(map);
      }

      return result;
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil rekap absensi Tahfidz: ${e.message}');
    } catch (e) {
      throw Exception('Gagal mengambil rekap absensi Tahfidz: $e');
    }
  }

  // ================================================================
  // FORMAT DATE
  // ================================================================

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
