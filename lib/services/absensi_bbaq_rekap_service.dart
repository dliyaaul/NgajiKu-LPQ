import 'package:ptl_mobile/models/absensi_bbaq/bbaq_rekap_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiBbaqRekapService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // GET PENGAJAR BBAQ BERDASARKAN PROGRAM
  // ============================================================

  Future<List<Map<String, dynamic>>> getPengajarBbaqByProgram(
    String programId, {
    String? kelasPengajaranId,
  }) async {
    try {
      var query = _supabase
          .from('pengajar_programs')
          .select('''
            id,
            pengajar_id,
            pengajar:profiles!pengajar_programs_pengajar_id_fkey(
              id,
              username
            )
          ''')
          .eq('program_id', programId);

      if (kelasPengajaranId != null && kelasPengajaranId.isNotEmpty) {
        query = query.eq('kelas_pengajaran_id', kelasPengajaranId);
      }

      final response = await query;

      final result = <Map<String, dynamic>>[];

      for (final raw in response) {
        final item = Map<String, dynamic>.from(raw);

        final pengajar = item['pengajar'] is Map
            ? Map<String, dynamic>.from(item['pengajar'])
            : <String, dynamic>{};

        final id = pengajar['id']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        result.add({
          'id': id,
          'username': pengajar['username']?.toString() ?? '-',
        });
      }

      result.sort(
        (a, b) => (a['username'] ?? '').toString().toLowerCase().compareTo(
          (b['username'] ?? '').toString().toLowerCase(),
        ),
      );

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil daftar pengajar BBAQ: $e');
    }
  }

  // ============================================================
  // GET TANGGAL BBAQ
  // ============================================================

  Future<List<DateTime>> getTanggalBbaq({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      var query = _supabase
          .from('bbaq_pertemuan')
          .select('tanggal')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      if (pengajarId != null && pengajarId.isNotEmpty) {
        query = query.eq('pengajar_id', pengajarId);
      }

      final response = await query.order('tanggal', ascending: true);

      final tanggalSet = <String>{};

      for (final raw in response) {
        final tanggal = raw['tanggal']?.toString();

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        tanggalSet.add(tanggal);
      }

      final result = tanggalSet.map(DateTime.parse).toList();
      result.sort();

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil tanggal pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN BBAQ
  //
  // Digunakan oleh provider untuk mendapatkan daftar pertemuan.
  //
  // CATATAN:
  // jam_mulai SUDAH DIHAPUS DARI DATABASE,
  // sehingga TIDAK BOLEH dimasukkan ke SELECT.
  // ============================================================

  Future<List<Map<String, dynamic>>> getPertemuanBbaq({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      var query = _supabase
          .from('bbaq_pertemuan')
          .select('''
            id,
            program_id,
            tanggal,
            pengajar_id,
            pengganti_pengajar_id,
            materi_pembelajaran,
            metode,

            pengajar:profiles!bbaq_pertemuan_pengajar_fkey(
              id,
              username
            ),

            pengganti_pengajar:pengajar_pengganti!bbaq_pertemuan_pengganti_pengajar_id_fkey(
              id,
              nama,
              no_hp,
              aktif
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      if (pengajarId != null && pengajarId.isNotEmpty) {
        query = query.eq('pengajar_id', pengajarId);
      }

      final response = await query.order('tanggal', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan BBAQ: $e');
    }
  }

  // ============================================================
  // GET REKAP BBAQ
  // ============================================================

  Future<List<BbaqRekapModel>> getRekapBbaq({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ==========================================================
      // AMBIL SANTRI PROGRAM
      // ==========================================================

      final santriPrograms = await _supabase
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

      if (santriPrograms.isEmpty) {
        return [];
      }

      // ==========================================================
      // FILTER SANTRI BERDASARKAN PENGAJAR
      // ==========================================================

      final filteredSantriPrograms = pengajarId == null || pengajarId.isEmpty
          ? santriPrograms
          : santriPrograms.where((raw) {
              final item = Map<String, dynamic>.from(raw);

              return item['pengajar_id']?.toString() == pengajarId;
            }).toList();

      if (filteredSantriPrograms.isEmpty) {
        return [];
      }

      // ==========================================================
      // AMBIL PERTEMUAN
      // ==========================================================

      var pertemuanQuery = _supabase
          .from('bbaq_pertemuan')
          .select('''
            id,
            tanggal
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      if (pengajarId != null && pengajarId.isNotEmpty) {
        pertemuanQuery = pertemuanQuery.eq('pengajar_id', pengajarId);
      }

      final pertemuanResponse = await pertemuanQuery.order(
        'tanggal',
        ascending: true,
      );

      final pertemuanList = List<Map<String, dynamic>>.from(pertemuanResponse);

      if (pertemuanList.isEmpty) {
        return [];
      }

      // ==========================================================
      // MAP TANGGAL
      // ==========================================================

      final tanggalList = <String>[];

      for (final pertemuan in pertemuanList) {
        final tanggal = pertemuan['tanggal']?.toString();

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        if (!tanggalList.contains(tanggal)) {
          tanggalList.add(tanggal);
        }
      }

      tanggalList.sort();

      if (tanggalList.isEmpty) {
        return [];
      }

      // ==========================================================
      // AMBIL ABSENSI
      // ==========================================================

      final pertemuanIds = pertemuanList
          .map((item) => item['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (pertemuanIds.isEmpty) {
        return [];
      }

      final absensiResponse = await _supabase
          .from('absensi')
          .select('''
            id,
            bbaq_pertemuan_id,
            santri_program_id,
            status
          ''')
          .inFilter('bbaq_pertemuan_id', pertemuanIds);

      // ==========================================================
      // MAP TANGGAL BERDASARKAN ID PERTEMUAN
      // ==========================================================

      final tanggalByPertemuanId = <String, String>{};

      for (final pertemuan in pertemuanList) {
        final id = pertemuan['id']?.toString();

        final tanggal = pertemuan['tanggal']?.toString();

        if (id == null || id.isEmpty || tanggal == null || tanggal.isEmpty) {
          continue;
        }

        tanggalByPertemuanId[id] = tanggal;
      }

      // ==========================================================
      // MAP STATUS
      //
      // KEY:
      // santri_program_id + tanggal
      // ==========================================================

      final statusMap = <String, String>{};

      for (final raw in absensiResponse) {
        final item = Map<String, dynamic>.from(raw);

        final santriProgramId = item['santri_program_id']?.toString() ?? '';

        final pertemuanId = item['bbaq_pertemuan_id']?.toString() ?? '';

        final status = item['status']?.toString() ?? '-';

        if (santriProgramId.isEmpty || pertemuanId.isEmpty) {
          continue;
        }

        final tanggal = tanggalByPertemuanId[pertemuanId];

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        final key = '${santriProgramId}_$tanggal';

        statusMap[key] = status;
      }

      // ==========================================================
      // BUILD REKAP
      // ==========================================================

      final result = <BbaqRekapModel>[];

      for (final raw in filteredSantriPrograms) {
        final item = Map<String, dynamic>.from(raw);

        final santriProgramId = item['id']?.toString() ?? '';

        final santriId = item['santri_id']?.toString() ?? '';

        if (santriProgramId.isEmpty) {
          continue;
        }

        final santri = item['santri'] is Map
            ? Map<String, dynamic>.from(item['santri'])
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

        result.add(
          BbaqRekapModel(
            santriProgramId: santriProgramId,
            santriId: santriId,
            namaSantri: namaSantri,
            statusPerTanggal: statusPerTanggal,
          ),
        );
      }

      // ==========================================================
      // SORT NAMA SANTRI
      // ==========================================================

      result.sort(
        (a, b) =>
            a.namaSantri.toLowerCase().compareTo(b.namaSantri.toLowerCase()),
      );

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil rekap absensi BBAQ: $e');
    }
  }

  // ============================================================
  // GET DETAIL ABSENSI BBAQ
  //
  // Digunakan untuk:
  // Laporan PDF Per Tanggal
  // ============================================================

  Future<List<Map<String, dynamic>>> getDetailAbsensiBbaq({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ==========================================================
      // AMBIL PERTEMUAN
      // ==========================================================

      var pertemuanQuery = _supabase
          .from('bbaq_pertemuan')
          .select('''
      id,
      program_id,
      kelas_pengajaran_id,
      tanggal,
      pengajar_id,
      pengganti_pengajar_id,
      materi_pembelajaran,
      metode,

      pengajar:profiles!bbaq_pertemuan_pengajar_fkey(
        id,
        username
      ),

      pengganti_pengajar:pengajar_pengganti!bbaq_pertemuan_pengganti_pengajar_id_fkey(
        id,
        nama,
        no_hp,
        aktif
      )
    ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      if (pengajarId != null && pengajarId.isNotEmpty) {
        pertemuanQuery = pertemuanQuery.eq('pengajar_id', pengajarId);
      }

      final pertemuanResponse = await pertemuanQuery.order(
        'tanggal',
        ascending: true,
      );

      final pertemuanList = List<Map<String, dynamic>>.from(pertemuanResponse);

      if (pertemuanList.isEmpty) {
        return [];
      }

      // ==========================================================
      // AMBIL ID PERTEMUAN
      // ==========================================================

      final pertemuanIds = pertemuanList
          .map((item) => item['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (pertemuanIds.isEmpty) {
        return [];
      }

      // ==========================================================
      // AMBIL ABSENSI
      // ==========================================================

      final absensiResponse = await _supabase
          .from('absensi')
          .select('''
            id,
            bbaq_pertemuan_id,
            santri_program_id,
            status
          ''')
          .inFilter('bbaq_pertemuan_id', pertemuanIds);

      if (absensiResponse.isEmpty) {
        return [];
      }

      // ==========================================================
      // AMBIL SANTRI PROGRAM
      // ==========================================================

      final santriProgramIds = absensiResponse
          .map((item) => item['santri_program_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (santriProgramIds.isEmpty) {
        return [];
      }

      final santriPrograms = await _supabase
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
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .eq('program_id', programId)
          .inFilter('id', santriProgramIds);

      // ==========================================================
      // MAP SANTRI PROGRAM
      // ==========================================================

      final santriMap = <String, Map<String, dynamic>>{};

      for (final raw in santriPrograms) {
        final item = Map<String, dynamic>.from(raw);

        final id = item['id']?.toString();

        if (id != null && id.isNotEmpty) {
          santriMap[id] = item;
        }
      }

      // ==========================================================
      // MAP PERTEMUAN
      // ==========================================================

      final pertemuanMap = <String, Map<String, dynamic>>{};

      for (final pertemuan in pertemuanList) {
        final id = pertemuan['id']?.toString();

        if (id != null && id.isNotEmpty) {
          pertemuanMap[id] = pertemuan;
        }
      }

      // ==========================================================
      // BUILD RESULT
      // ==========================================================

      final result = <Map<String, dynamic>>[];

      for (final raw in absensiResponse) {
        final absensi = Map<String, dynamic>.from(raw);

        final santriProgramId = absensi['santri_program_id']?.toString();

        final pertemuanId = absensi['bbaq_pertemuan_id']?.toString();

        if (santriProgramId == null || pertemuanId == null) {
          continue;
        }

        final santriProgram = santriMap[santriProgramId];

        final pertemuan = pertemuanMap[pertemuanId];

        if (santriProgram == null || pertemuan == null) {
          continue;
        }

        result.add({
          ...absensi,
          'santri_program': santriProgram,
          'pertemuan': pertemuan,
        });
      }

      // ==========================================================
      // SORT
      // Tanggal → Nama Santri
      // ==========================================================

      result.sort((a, b) {
        final pertemuanA = a['pertemuan'] as Map<String, dynamic>;

        final pertemuanB = b['pertemuan'] as Map<String, dynamic>;

        final tanggalA = pertemuanA['tanggal']?.toString() ?? '';

        final tanggalB = pertemuanB['tanggal']?.toString() ?? '';

        final dateCompare = tanggalA.compareTo(tanggalB);

        if (dateCompare != 0) {
          return dateCompare;
        }

        final santriA = a['santri_program'] is Map
            ? Map<String, dynamic>.from(a['santri_program'])
            : <String, dynamic>{};

        final santriB = b['santri_program'] is Map
            ? Map<String, dynamic>.from(b['santri_program'])
            : <String, dynamic>{};

        final profileA = santriA['santri'] is Map
            ? Map<String, dynamic>.from(santriA['santri'])
            : <String, dynamic>{};

        final profileB = santriB['santri'] is Map
            ? Map<String, dynamic>.from(santriB['santri'])
            : <String, dynamic>{};

        final namaA = profileA['username']?.toString() ?? '';

        final namaB = profileB['username']?.toString() ?? '';

        return namaA.toLowerCase().compareTo(namaB.toLowerCase());
      });

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil detail absensi BBAQ: $e');
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
