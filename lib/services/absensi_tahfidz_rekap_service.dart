import 'package:ptl_mobile/models/absensi_tahfidz/absensi_tahfidz_rekap_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiTahfidzRekapService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // 1. GET DAFTAR PENGAJAR BERDASARKAN PROGRAM DAN KELAS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPengajarTahfidzByProgram(
    String programId,
    String kelasPengajaranId,
  ) async {
    try {
      final response = await _supabase
          .from('pengajar_programs')
          .select('''
            pengajar_id,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId);

      final result = <Map<String, dynamic>>[];

      for (final item in response) {
        final map = Map<String, dynamic>.from(item);
        final pengajar = map['pengajar'];

        if (pengajar is Map) {
          result.add({'id': pengajar['id'], 'username': pengajar['username']});
        }
      }

      result.sort(
        (a, b) => (a['username'] ?? '').toString().toLowerCase().compareTo(
          (b['username'] ?? '').toString().toLowerCase(),
        ),
      );

      return result;
    } catch (e) {
      throw Exception(
        'Gagal mengambil pengajar Tahfidz berdasarkan program dan kelas: $e',
      );
    }
  }

  // ============================================================
  // 2. HELPER GET SANTRI PROGRAM IDS
  // ============================================================

  Future<List<String>> _getSantriProgramIds({
    required String programId,
    required String kelasPengajaranId,
    String? pengajarId,
  }) async {
    var query = _supabase
        .from('santri_programs')
        .select('id')
        .eq('program_id', programId)
        .eq('kelas_pengajaran_id', kelasPengajaranId);

    if (pengajarId != null && pengajarId.isNotEmpty) {
      query = query.eq('pengajar_id', pengajarId);
    }

    final response = await query;

    return List<Map<String, dynamic>>.from(response)
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  // ============================================================
  // 3. GET DAFTAR TANGGAL ABSENSI TAHFIDZ
  // ============================================================

  Future<List<DateTime>> getTanggalTahfidz({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // Ambil ID santri program yang sesuai kelas.
      final santriProgramIds = await _getSantriProgramIds(
        programId: programId,
        kelasPengajaranId: kelasPengajaranId,
        pengajarId: pengajarId,
      );

      if (santriProgramIds.isEmpty) {
        return [];
      }

      // Ambil tanggal absensi hanya dari santri program tersebut.
      final response = await _supabase
          .from('absensi_tahfidz')
          .select('tanggal, santri_program_id')
          .inFilter('santri_program_id', santriProgramIds)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal))
          .order('tanggal', ascending: true);

      final tanggalSet = <String>{};

      for (final raw in response) {
        final item = Map<String, dynamic>.from(raw);
        final tanggal = item['tanggal']?.toString();

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        tanggalSet.add(tanggal);
      }

      final result = tanggalSet
          .map((tanggal) => DateTime.parse(tanggal))
          .toList();

      result.sort();

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil tanggal absensi Tahfidz: $e');
    }
  }

  // ============================================================
  // 4. GET REKAP ABSENSI TAHFIDZ
  // ============================================================

  Future<List<AbsensiTahfidzRekapModel>> getRekapTahfidz({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ----------------------------------------------------------
      // 1. Ambil santri program berdasarkan program dan kelas.
      // ----------------------------------------------------------

      var santriProgramQuery = _supabase
          .from('santri_programs')
          .select('''
            id,
            santri_id,
            pengajar_id,
            santri:profiles!santri_programs_santri_id_fkey(
              id,
              username
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId);

      if (pengajarId != null && pengajarId.isNotEmpty) {
        santriProgramQuery = santriProgramQuery.eq('pengajar_id', pengajarId);
      }

      final santriProgramsResponse = await santriProgramQuery;

      final santriPrograms = List<Map<String, dynamic>>.from(
        santriProgramsResponse,
      );

      if (santriPrograms.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 2. Ambil ID santri program.
      // ----------------------------------------------------------

      final santriProgramIds = santriPrograms
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (santriProgramIds.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 3. Ambil absensi hanya dari santri program kelas ini.
      // ----------------------------------------------------------

      final absensiResponse = await _supabase
          .from('absensi_tahfidz')
          .select('''
            id,
            santri_program_id,
            tanggal,
            status,
            jenis_tahfidz,
            surat,
            ayat_mulai,
            ayat_selesai,
            keterangan
          ''')
          .inFilter('santri_program_id', santriProgramIds)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal))
          .order('tanggal', ascending: true);

      // ----------------------------------------------------------
      // 4. Buat status map.
      // ----------------------------------------------------------

      final statusMap = <String, String>{};

      for (final raw in absensiResponse) {
        final item = Map<String, dynamic>.from(raw);

        final santriProgramId = item['santri_program_id']?.toString() ?? '';

        final tanggal = item['tanggal']?.toString() ?? '';

        final status = item['status']?.toString() ?? '-';

        if (santriProgramId.isEmpty || tanggal.isEmpty) {
          continue;
        }

        final key = '${santriProgramId}_$tanggal';

        statusMap[key] = status;
      }

      // ----------------------------------------------------------
      // 5. Ambil tanggal absensi.
      // ----------------------------------------------------------

      final tanggalSet = <String>{};

      for (final raw in absensiResponse) {
        final item = Map<String, dynamic>.from(raw);

        final tanggal = item['tanggal']?.toString();

        if (tanggal != null && tanggal.isNotEmpty) {
          tanggalSet.add(tanggal);
        }
      }

      final tanggalList = tanggalSet.toList()..sort();

      // ----------------------------------------------------------
      // 6. Buat rekap per santri.
      // ----------------------------------------------------------

      final rekapResult = <AbsensiTahfidzRekapModel>[];

      for (final raw in santriPrograms) {
        final santriProgramId = raw['id']?.toString() ?? '';

        final santriId = raw['santri_id']?.toString() ?? '';

        final santri = raw['santri'] is Map
            ? Map<String, dynamic>.from(raw['santri'])
            : <String, dynamic>{};

        final username = santri['username']?.toString().trim();

        final namaSantri = username != null && username.isNotEmpty
            ? username
            : '-';

        final statusPerTanggal = <String, String>{};

        for (final tanggal in tanggalList) {
          final key = '${santriProgramId}_$tanggal';

          statusPerTanggal[tanggal] = statusMap[key] ?? '-';
        }

        rekapResult.add(
          AbsensiTahfidzRekapModel(
            santriProgramId: santriProgramId,
            santriId: santriId,
            namaSantri: namaSantri,
            statusPerTanggal: statusPerTanggal,
          ),
        );
      }

      // ----------------------------------------------------------
      // 7. Urutkan berdasarkan nama santri.
      // ----------------------------------------------------------

      rekapResult.sort(
        (a, b) =>
            a.namaSantri.toLowerCase().compareTo(b.namaSantri.toLowerCase()),
      );

      return rekapResult;
    } catch (e) {
      throw Exception('Gagal mengambil rekap absensi Tahfidz: $e');
    }
  }

  // ============================================================
  // 5. GET DETAIL ABSENSI TAHFIDZ
  // ============================================================

  Future<List<Map<String, dynamic>>> getDetailAbsensiTahfidz({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ----------------------------------------------------------
      // 1. Ambil santri program sesuai program dan kelas.
      // ----------------------------------------------------------

      var santriProgramQuery = _supabase
          .from('santri_programs')
          .select('''
            id,
            santri_id,
            pengajar_id,
            santri:profiles!santri_programs_santri_id_fkey(
              id,
              username
            ),
            pengajar:profiles!santri_programs_pengajar_id_fkey(
              id,
              username
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId);

      if (pengajarId != null && pengajarId.isNotEmpty) {
        santriProgramQuery = santriProgramQuery.eq('pengajar_id', pengajarId);
      }

      final santriProgramResponse = await santriProgramQuery;

      final santriProgramList = List<Map<String, dynamic>>.from(
        santriProgramResponse,
      );

      if (santriProgramList.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 2. Ambil ID santri program.
      // ----------------------------------------------------------

      final santriProgramIds = santriProgramList
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (santriProgramIds.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 3. Ambil absensi berdasarkan santri program tersebut.
      // ----------------------------------------------------------

      final absensiResponse = await _supabase
          .from('absensi_tahfidz')
          .select('''
            id,
            santri_program_id,
            tanggal,
            status,
            jenis_tahfidz,
            surat,
            ayat_mulai,
            ayat_selesai,
            keterangan
          ''')
          .inFilter('santri_program_id', santriProgramIds)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal))
          .order('tanggal', ascending: true);

      final absensiList = List<Map<String, dynamic>>.from(absensiResponse);

      if (absensiList.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 4. Buat map santri program.
      // ----------------------------------------------------------

      final santriProgramMap = <String, Map<String, dynamic>>{};

      for (final item in santriProgramList) {
        final id = item['id']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        santriProgramMap[id] = item;
      }

      // ----------------------------------------------------------
      // 5. Gabungkan absensi dan data santri program.
      // ----------------------------------------------------------

      final result = <Map<String, dynamic>>[];

      for (final absensi in absensiList) {
        final santriProgramId = absensi['santri_program_id']?.toString() ?? '';

        if (santriProgramId.isEmpty) {
          continue;
        }

        final santriProgram = santriProgramMap[santriProgramId];

        // Santri di luar program/kelas/pengajar terpilih diabaikan.
        if (santriProgram == null) {
          continue;
        }

        final resultItem = Map<String, dynamic>.from(absensi);

        resultItem['santri_program'] = santriProgram;

        result.add(resultItem);
      }

      // ----------------------------------------------------------
      // 6. Urutkan berdasarkan tanggal dan nama santri.
      // ----------------------------------------------------------

      result.sort((a, b) {
        final tanggalA = a['tanggal']?.toString() ?? '';
        final tanggalB = b['tanggal']?.toString() ?? '';

        final compareTanggal = tanggalA.compareTo(tanggalB);

        if (compareTanggal != 0) {
          return compareTanggal;
        }

        final santriProgramA = a['santri_program'];
        final santriProgramB = b['santri_program'];

        String namaA = '';
        String namaB = '';

        if (santriProgramA is Map) {
          final santri = santriProgramA['santri'];

          if (santri is Map) {
            namaA = santri['username']?.toString() ?? '';
          }
        }

        if (santriProgramB is Map) {
          final santri = santriProgramB['santri'];

          if (santri is Map) {
            namaB = santri['username']?.toString() ?? '';
          }
        }

        return namaA.toLowerCase().compareTo(namaB.toLowerCase());
      });

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil detail absensi Tahfidz: $e');
    }
  }

  // ============================================================
  // HELPER FORMAT TANGGAL
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
