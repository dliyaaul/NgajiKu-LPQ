import 'package:ptl_mobile/models/absensi_tarjamah/tarjamah_rekap_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiTarjamahRekapService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _pertemuanTable = 'tarjamah_pertemuan';
  static const String _absensiTable = 'absensi_tarjamah';

  // ============================================================
  // GET PENGAJAR TARJAMAH BERDASARKAN PROGRAM
  // ============================================================

  Future<List<Map<String, dynamic>>> getPengajarTarjamahByProgram(
    String programId, {
    required String kelasPengajaranId,
  }) async {
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
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('created_at', ascending: true);

      final result = <Map<String, dynamic>>[];

      for (final item in response as List) {
        final data = Map<String, dynamic>.from(item);

        final pengajar = data['pengajar'];

        if (pengajar is! Map) {
          continue;
        }

        final pengajarId = pengajar['id']?.toString();

        if (pengajarId == null || pengajarId.isEmpty) {
          continue;
        }

        result.add({
          'id': pengajarId,
          'username': pengajar['username']?.toString() ?? 'Tanpa Nama',
        });
      }

      return result;
    } catch (e) {
      throw Exception(
        'Gagal mengambil pengajar Tarjamah berdasarkan program: $e',
      );
    }
  }

  // ============================================================
  // GET TANGGAL PERTEMUAN TARJAMAH
  // ============================================================

  Future<List<DateTime>> getTanggalTarjamah({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      var query = _supabase
          .from(_pertemuanTable)
          .select('''
            id,
            tanggal,
            pengajar_id,
            pengajar_pengganti_id
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      final response = await query.order('tanggal', ascending: true);

      final tanggalSet = <String>{};

      for (final item in response as List) {
        final data = Map<String, dynamic>.from(item);

        if (pengajarId != null && pengajarId.trim().isNotEmpty) {
          final pengajarUtamaId = data['pengajar_id']?.toString();
          final pengajarPenggantiId = data['pengajar_pengganti_id']?.toString();

          final cocokPengajarUtama = pengajarUtamaId == pengajarId;
          final cocokPengganti = pengajarPenggantiId == pengajarId;

          if (!cocokPengajarUtama && !cocokPengganti) {
            continue;
          }
        }

        final tanggal = data['tanggal']?.toString();

        if (tanggal != null && tanggal.isNotEmpty) {
          tanggalSet.add(tanggal);
        }
      }

      final result = tanggalSet
          .map((tanggal) => DateTime.parse(tanggal))
          .toList();

      result.sort();

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil tanggal pertemuan Tarjamah: $e');
    }
  }

  // ============================================================
  // GET REKAP TARJAMAH
  // ============================================================

  Future<List<TarjamahRekapModel>> getRekapTarjamah({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ----------------------------------------------------------
      // 1. Ambil daftar pertemuan
      // ----------------------------------------------------------

      var pertemuanQuery = _supabase
          .from(_pertemuanTable)
          .select('''
            id,
            program_id,
            kelas_pengajaran_id,
            tanggal,
            pengajar_id,
            pengajar_pengganti_id
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal));

      final pertemuanResponse = await pertemuanQuery.order(
        'tanggal',
        ascending: true,
      );

      final pertemuanList = <Map<String, dynamic>>[];

      for (final item in pertemuanResponse as List) {
        final data = Map<String, dynamic>.from(item);

        // --------------------------------------------------------
        // Filter pengajar
        // --------------------------------------------------------

        if (pengajarId != null && pengajarId.trim().isNotEmpty) {
          final pengajarUtamaId = data['pengajar_id']?.toString();
          final pengajarPenggantiId = data['pengajar_pengganti_id']?.toString();

          final cocokPengajarUtama = pengajarUtamaId == pengajarId;
          final cocokPengganti = pengajarPenggantiId == pengajarId;

          if (!cocokPengajarUtama && !cocokPengganti) {
            continue;
          }
        }

        pertemuanList.add(data);
      }

      if (pertemuanList.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 2. Ambil ID pertemuan
      // ----------------------------------------------------------

      final pertemuanIds = pertemuanList
          .map((item) => item['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (pertemuanIds.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 3. Ambil semua absensi
      // ----------------------------------------------------------

      final absensiResponse = await _supabase
          .from(_absensiTable)
          .select('''
            id,
            tarjamah_pertemuan_id,
            santri_program_id,
            status
          ''')
          .inFilter('tarjamah_pertemuan_id', pertemuanIds);

      // ----------------------------------------------------------
      // 4. Ambil santri program
      // ----------------------------------------------------------

      final santriProgramResponse = await _supabase
          .from('santri_programs')
          .select('''
            id,
            santri_id,
            program_id,
            profiles:santri_id(
              id,
              username
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId);

      // ----------------------------------------------------------
      // 5. Buat mapping santri
      // ----------------------------------------------------------

      final santriMap = <String, Map<String, dynamic>>{};

      for (final item in santriProgramResponse as List) {
        final data = Map<String, dynamic>.from(item);

        final santriProgramId = data['id']?.toString();

        if (santriProgramId == null || santriProgramId.isEmpty) {
          continue;
        }

        final santriId = data['santri_id']?.toString() ?? '';

        final profile = data['profiles'];

        String namaSantri = 'Tanpa Nama';

        if (profile is Map) {
          namaSantri = profile['username']?.toString() ?? 'Tanpa Nama';
        }

        santriMap[santriProgramId] = {
          'santriProgramId': santriProgramId,
          'santriId': santriId,
          'namaSantri': namaSantri,
        };
      }

      // ----------------------------------------------------------
      // 6. Mapping absensi
      //
      // Key:
      // santriProgramId
      //   -> tanggal
      //       -> status
      // ----------------------------------------------------------

      final statusMap = <String, Map<String, String>>{};

      // Mapping ID pertemuan -> tanggal
      final tanggalPertemuanMap = <String, String>{};

      for (final item in pertemuanList) {
        final id = item['id']?.toString();
        final tanggal = item['tanggal']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        tanggalPertemuanMap[id] = tanggal;
      }

      for (final item in absensiResponse as List) {
        final data = Map<String, dynamic>.from(item);

        final santriProgramId = data['santri_program_id']?.toString();

        final pertemuanId = data['tarjamah_pertemuan_id']?.toString();

        if (santriProgramId == null ||
            santriProgramId.isEmpty ||
            pertemuanId == null ||
            pertemuanId.isEmpty) {
          continue;
        }

        final tanggal = tanggalPertemuanMap[pertemuanId];

        if (tanggal == null || tanggal.isEmpty) {
          continue;
        }

        final status = data['status']?.toString() ?? 'Alpa';

        statusMap.putIfAbsent(santriProgramId, () => <String, String>{});

        statusMap[santriProgramId]![tanggal] = status;
      }

      // ----------------------------------------------------------
      // 7. Buat daftar tanggal
      // ----------------------------------------------------------

      final tanggalSet = <String>{};

      for (final item in pertemuanList) {
        final tanggal = item['tanggal']?.toString();

        if (tanggal != null && tanggal.isNotEmpty) {
          tanggalSet.add(tanggal);
        }
      }

      final tanggalList = tanggalSet.toList()..sort();

      // ----------------------------------------------------------
      // 8. Buat hasil rekap
      // ----------------------------------------------------------

      final result = <TarjamahRekapModel>[];

      for (final santri in santriMap.values) {
        final santriProgramId = santri['santriProgramId']?.toString() ?? '';

        final santriId = santri['santriId']?.toString() ?? '';

        final namaSantri = santri['namaSantri']?.toString() ?? 'Tanpa Nama';

        if (santriProgramId.isEmpty) {
          continue;
        }

        final statusPerTanggal = <String, String>{};

        for (final tanggal in tanggalList) {
          statusPerTanggal[tanggal] =
              statusMap[santriProgramId]?[tanggal] ?? '-';
        }

        result.add(
          TarjamahRekapModel(
            santriProgramId: santriProgramId,
            santriId: santriId,
            namaSantri: namaSantri,
            statusPerTanggal: statusPerTanggal,
          ),
        );
      }

      // ----------------------------------------------------------
      // 9. Urutkan berdasarkan nama santri
      // ----------------------------------------------------------

      result.sort(
        (a, b) =>
            a.namaSantri.toLowerCase().compareTo(b.namaSantri.toLowerCase()),
      );

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil rekap absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // GET DETAIL ABSENSI TARJAMAH
  // ============================================================

  Future<List<Map<String, dynamic>>> getDetailAbsensiTarjamah({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      // ----------------------------------------------------------
      // 1. Ambil pertemuan
      // ----------------------------------------------------------

      final pertemuanResponse = await _supabase
          .from(_pertemuanTable)
          .select('''
            id,
            program_id,
            kelas_pengajaran_id,
            tanggal,
            pengajar_id,
            pengajar_pengganti_id,
            materi_pembelajaran,
            metode,
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
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal))
          .order('tanggal', ascending: true);

      final pertemuanList = <Map<String, dynamic>>[];

      for (final item in pertemuanResponse as List) {
        final data = Map<String, dynamic>.from(item);

        if (pengajarId != null && pengajarId.trim().isNotEmpty) {
          final pengajarUtamaId = data['pengajar_id']?.toString();
          final pengajarPenggantiId = data['pengajar_pengganti_id']?.toString();

          if (pengajarUtamaId != pengajarId &&
              pengajarPenggantiId != pengajarId) {
            continue;
          }
        }

        pertemuanList.add(data);
      }

      if (pertemuanList.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 2. Ambil ID pertemuan
      // ----------------------------------------------------------

      final pertemuanIds = pertemuanList
          .map((item) => item['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      if (pertemuanIds.isEmpty) {
        return [];
      }

      // ----------------------------------------------------------
      // 3. Ambil absensi
      // ----------------------------------------------------------

      final absensiResponse = await _supabase
          .from(_absensiTable)
          .select('''
            id,
            tarjamah_pertemuan_id,
            santri_program_id,
            status,
            created_by,
            created_at,
            santri_program:santri_programs!absensi_tarjamah_santri_program_fkey(
              id,
              santri_id,
              santri:profiles!santri_programs_santri_id_fkey(
                id,
                username
              )
            )
          ''')
          .inFilter('tarjamah_pertemuan_id', pertemuanIds)
          .order('created_at', ascending: true);

      // ----------------------------------------------------------
      // 4. Gabungkan data pertemuan + absensi
      // ----------------------------------------------------------

      final result = <Map<String, dynamic>>[];

      for (final pertemuan in pertemuanList) {
        final pertemuanId = pertemuan['id']?.toString();

        if (pertemuanId == null || pertemuanId.isEmpty) {
          continue;
        }

        final tanggal = pertemuan['tanggal']?.toString();

        final pengajar = pertemuan['pengajar'];

        final pengajarPengganti = pertemuan['pengajar_pengganti'];

        final namaPengajar = pengajar is Map
            ? pengajar['username']?.toString()
            : null;

        final namaPengajarPengganti = pengajarPengganti is Map
            ? pengajarPengganti['nama']?.toString()
            : null;

        final absensi = (absensiResponse as List)
            .where(
              (item) =>
                  item['tarjamah_pertemuan_id']?.toString() == pertemuanId,
            )
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        result.add({
          'pertemuan_id': pertemuanId,
          'tanggal': tanggal,
          'pengajar_id': pertemuan['pengajar_id'],
          'pengajar_pengganti_id': pertemuan['pengajar_pengganti_id'],
          'nama_pengajar': namaPengajar,
          'nama_pengajar_pengganti': namaPengajarPengganti,
          'materi_pembelajaran': pertemuan['materi_pembelajaran'],
          'metode': pertemuan['metode'],
          'absensi': absensi,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil detail absensi Tarjamah: $e');
    }
  }

  // ============================================================
  // GET PERTEMUAN TARJAMAH
  // ============================================================

  Future<List<Map<String, dynamic>>> getPertemuanTarjamah({
    required String programId,
    required String kelasPengajaranId,
    required DateTime dariTanggal,
    required DateTime sampaiTanggal,
    String? pengajarId,
  }) async {
    try {
      final response = await _supabase
          .from(_pertemuanTable)
          .select('''
            id,
            program_id,
            kelas_pengajaran_id,
            tanggal,
            pengajar_id,
            pengajar_pengganti_id,
            materi_pembelajaran,
            metode,
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
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .gte('tanggal', _formatDate(dariTanggal))
          .lte('tanggal', _formatDate(sampaiTanggal))
          .order('tanggal', ascending: true);

      final result = <Map<String, dynamic>>[];

      for (final item in response as List) {
        final data = Map<String, dynamic>.from(item);

        if (pengajarId != null && pengajarId.trim().isNotEmpty) {
          final pengajarUtamaId = data['pengajar_id']?.toString();
          final pengajarPenggantiId = data['pengajar_pengganti_id']?.toString();

          if (pengajarUtamaId != pengajarId &&
              pengajarPenggantiId != pengajarId) {
            continue;
          }
        }

        result.add(data);
      }

      return result;
    } catch (e) {
      throw Exception('Gagal mengambil data pertemuan Tarjamah: $e');
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
