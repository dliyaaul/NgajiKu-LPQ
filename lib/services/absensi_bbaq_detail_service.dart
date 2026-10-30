import 'package:supabase_flutter/supabase_flutter.dart';

/// Service detail absensi BBAQ.
///
/// Data santri difilter berdasarkan program dan kelas pengajaran pertemuan.
/// Batas input/edit/hapus selalu dihitung dari `bbaq_pertemuan.created_at`.
class AbsensiBbaqDetailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // SANTRI PER KELAS
  // ============================================================

  Future<List<Map<String, dynamic>>> getSantriBbaq(
    String programId, {
    String? kelasPengajaranId,
  }) async {
    if (kelasPengajaranId == null || kelasPengajaranId.trim().isEmpty) {
      throw Exception(
        'Pertemuan ini belum memiliki Kelas Pengajaran. '
        'Hubungkan pertemuan ke kelas terlebih dahulu sebelum mengisi absensi.',
      );
    }

    try {
      final response = await _supabase
          .from('santri_programs')
          .select('''
            id,
            santri_id,
            program_id,
            kelas_type_id,
            kelas_pengajaran_id,
            created_at,
            santri:profiles!santri_programs_santri_id_fkey(
              id,
              username,
              email
            )
          ''')
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', kelasPengajaranId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data santri BBAQ: ${e.message}');
    }
  }

  // ============================================================
  // ABSENSI PER PERTEMUAN
  // ============================================================

  Future<List<Map<String, dynamic>>> getAbsensiByPertemuan(
    String pertemuanId,
  ) async {
    try {
      final response = await _supabase
          .from('absensi')
          .select('*')
          .eq('bbaq_pertemuan_id', pertemuanId);

      return (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal mengambil data absensi: ${e.message}');
    }
  }

  // ============================================================
  // DETAIL ABSENSI: KELAS -> SANTRI -> ABSENSI PERTEMUAN
  // ============================================================

  Future<List<Map<String, dynamic>>> getDetailAbsensi(
    String pertemuanId,
    String programId, {
    required String kelasPengajaranId,
  }) async {
    if (kelasPengajaranId.trim().isEmpty) {
      throw Exception(
        'Pertemuan lama ini belum memiliki Kelas Pengajaran. '
        'Hubungkan pertemuan ke kelas terlebih dahulu sebelum mengisi absensi.',
      );
    }

    try {
      final pertemuan = await _supabase
          .from('bbaq_pertemuan')
          .select('id, program_id, kelas_pengajaran_id')
          .eq('id', pertemuanId)
          .maybeSingle();

      if (pertemuan == null) {
        throw Exception('Pertemuan BBAQ tidak ditemukan.');
      }
      if (pertemuan['program_id']?.toString() != programId ||
          pertemuan['kelas_pengajaran_id']?.toString() != kelasPengajaranId) {
        throw Exception(
          'Kelas atau program tidak sesuai dengan pertemuan yang dipilih.',
        );
      }

      final results = await Future.wait([
        getSantriBbaq(programId, kelasPengajaranId: kelasPengajaranId),
        getAbsensiByPertemuan(pertemuanId),
      ]);
      final santri = results[0];
      final absensi = results[1];
      final absensiBySantriProgramId = <String, Map<String, dynamic>>{};

      for (final row in absensi) {
        final id = row['santri_program_id']?.toString();
        if (id != null && id.isNotEmpty) {
          absensiBySantriProgramId[id] = row;
        }
      }

      return santri.map((row) {
        final item = Map<String, dynamic>.from(row);
        item['absensi'] =
            absensiBySantriProgramId[item['id']?.toString() ?? ''];
        return item;
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat detail absensi BBAQ: ${e.message}');
    }
  }

  // ============================================================
  // BATAS WAKTU
  // ============================================================

  bool canInputAbsensi(DateTime createdAt) {
    return DateTime.now().isBefore(
      createdAt.toLocal().add(const Duration(hours: 24)),
    );
  }

  Duration remainingAbsensiTime(DateTime createdAt) {
    final batas = createdAt.toLocal().add(const Duration(hours: 24));
    final remaining = batas.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Memeriksa batas waktu pertemuan, bukan `absensi.created_at`.
  /// Parameter lama dipertahankan agar pemanggil yang sudah ada tetap kompatibel.
  bool canEditAbsensi(
    Map<String, dynamic>? absensi, {
    DateTime? pertemuanCreatedAt,
  }) {
    if (pertemuanCreatedAt != null) return canInputAbsensi(pertemuanCreatedAt);
    // Tanpa timestamp pertemuan, jangan menyimpulkan hak edit dari waktu
    // pembuatan baris absensi. Validasi definitif dilakukan ke database.
    return false;
  }

  Duration remainingEditTime(
    Map<String, dynamic>? absensi, {
    DateTime? pertemuanCreatedAt,
  }) {
    if (pertemuanCreatedAt == null) return Duration.zero;
    return remainingAbsensiTime(pertemuanCreatedAt);
  }

  Future<Map<String, dynamic>> _getValidMeeting(String pertemuanId) async {
    final meeting = await _supabase
        .from('bbaq_pertemuan')
        .select('id, program_id, kelas_pengajaran_id, tanggal, created_at')
        .eq('id', pertemuanId)
        .maybeSingle();

    if (meeting == null) throw Exception('Pertemuan BBAQ tidak ditemukan.');

    final classId = meeting['kelas_pengajaran_id']?.toString() ?? '';
    final programId = meeting['program_id']?.toString() ?? '';
    if (classId.isEmpty || programId.isEmpty) {
      throw Exception(
        'Pertemuan belum terhubung dengan Kelas Pengajaran. '
        'Absensi tidak dapat diproses.',
      );
    }

    final createdAt = DateTime.tryParse(
      meeting['created_at']?.toString() ?? '',
    );
    if (createdAt == null || !canInputAbsensi(createdAt)) {
      throw Exception(
        'Batas waktu input, edit, atau hapus absensi sudah berakhir '
        '(24 jam sejak pertemuan dibuat).',
      );
    }
    return Map<String, dynamic>.from(meeting);
  }

  // ============================================================
  // SIMPAN / PERBARUI / RESET ABSENSI
  // ============================================================

  Future<void> saveAbsensiBatch(
    List<Map<String, dynamic>> dataAbsensi, {
    required DateTime createdAt,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login. Silakan login kembali.');
    }
    if (dataAbsensi.isEmpty) {
      throw Exception('Tidak ada data absensi untuk diproses.');
    }

    final meetingIds = dataAbsensi
        .map((row) => row['bbaq_pertemuan_id']?.toString() ?? '')
        .toSet();
    if (meetingIds.length != 1 || meetingIds.contains('')) {
      throw Exception('Data absensi harus berasal dari satu pertemuan.');
    }
    final pertemuanId = meetingIds.single;

    try {
      // Timestamp dari database menjadi sumber kebenaran; `createdAt` hanya
      // dipertahankan untuk kompatibilitas dengan pemanggil lama.
      final meeting = await _getValidMeeting(pertemuanId);
      final classId = meeting['kelas_pengajaran_id'].toString();
      final programId = meeting['program_id'].toString();
      final meetingDate = meeting['tanggal'].toString();

      final ids = dataAbsensi
          .map((row) => row['santri_program_id']?.toString() ?? '')
          .toList();
      if (ids.any((id) => id.isEmpty) || ids.toSet().length != ids.length) {
        throw Exception('ID pendaftaran santri kosong atau duplikat.');
      }

      final enrollmentResponse = await _supabase
          .from('santri_programs')
          .select('id, santri_id, program_id, kelas_pengajaran_id')
          .inFilter('id', ids)
          .eq('program_id', programId)
          .eq('kelas_pengajaran_id', classId);
      final enrollments = (enrollmentResponse as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (enrollments.length != ids.length) {
        throw Exception(
          'Ada santri yang bukan anggota kelas pada pertemuan ini. '
          'Muat ulang halaman sebelum menyimpan.',
        );
      }

      final existingResponse = await _supabase
          .from('absensi')
          .select('id, santri_program_id, status')
          .eq('bbaq_pertemuan_id', pertemuanId)
          .inFilter('santri_program_id', ids);
      final existingByEnrollment = <String, Map<String, dynamic>>{
        for (final row in (existingResponse as List).map(
          (item) => Map<String, dynamic>.from(item),
        ))
          row['santri_program_id'].toString(): row,
      };

      const allowedStatuses = {
        'Hadir',
        'Izin',
        'Sakit',
        'Alpha',
        'Belum Absen',
      };
      final inserts = <Map<String, dynamic>>[];
      final updates = <Map<String, dynamic>>[];
      final deletes = <String>[];

      for (final row in dataAbsensi) {
        final enrollmentId = row['santri_program_id'].toString();
        final rawStatus = row['status']?.toString() ?? '';
        final status = rawStatus.toLowerCase() == 'alpa' ? 'Alpha' : rawStatus;
        if (!allowedStatuses.contains(status)) {
          throw Exception('Status absensi tidak valid: $rawStatus');
        }

        final existing = existingByEnrollment[enrollmentId];
        if (status == 'Belum Absen') {
          if (existing != null) deletes.add(existing['id'].toString());
          continue;
        }

        if (existing != null) {
          // Jangan kirim user_id/created_by/identitas ke UPDATE: trigger DB
          // memang melindungi kolom-kolom tersebut agar tidak berubah.
          updates.add({'id': existing['id'].toString(), 'status': status});
        } else {
          inserts.add({
            'user_id': user.id,
            'created_by': user.id,
            'program': 'BBAQ',
            'kegiatan': 'BBAQ',
            'tanggal': meetingDate,
            'status': status,
            'santri_program_id': enrollmentId,
            'bbaq_pertemuan_id': pertemuanId,
          });
        }
      }

      // Operasi dipisah agar kolom immutable tidak ikut terkirim saat update.
      // RLS tetap menjadi lapisan otorisasi utama pada setiap operasi.
      for (final item in updates) {
        final result = await _supabase
            .from('absensi')
            .update({
              'status': item['status'],
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', item['id'] as String)
            .select('id');
        if ((result as List).isEmpty) {
          throw Exception(
            'Absensi gagal diperbarui. Periksa akses atau batas waktu.',
          );
        }
      }

      if (inserts.isNotEmpty) {
        await _supabase.from('absensi').insert(inserts);
      }

      for (final id in deletes) {
        final result = await _supabase
            .from('absensi')
            .delete()
            .eq('id', id)
            .select('id');
        if ((result as List).isEmpty) {
          throw Exception(
            'Absensi gagal direset. Periksa akses atau batas waktu.',
          );
        }
      }
    } on PostgrestException catch (e) {
      throw Exception('Gagal menyimpan absensi BBAQ: ${e.message}');
    }
  }

  // ============================================================
  // HAPUS ABSENSI
  // ============================================================

  Future<void> deleteAbsensi(String absensiId) async {
    try {
      final row = await _supabase
          .from('absensi')
          .select('id, bbaq_pertemuan_id')
          .eq('id', absensiId)
          .maybeSingle();
      if (row == null) throw Exception('Data absensi tidak ditemukan.');

      final meetingId = row['bbaq_pertemuan_id']?.toString() ?? '';
      if (meetingId.isEmpty) {
        throw Exception(
          'Data ini bukan absensi yang terhubung ke pertemuan BBAQ.',
        );
      }
      await _getValidMeeting(meetingId);

      final result = await _supabase
          .from('absensi')
          .delete()
          .eq('id', absensiId)
          .select('id');
      if ((result as List).isEmpty) {
        throw Exception('Absensi tidak terhapus. Periksa akses RLS.');
      }
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus absensi BBAQ: ${e.message}');
    }
  }

  Future<void> deleteAbsensiByPertemuan(String pertemuanId) async {
    try {
      await _getValidMeeting(pertemuanId);
      final result = await _supabase
          .from('absensi')
          .delete()
          .eq('bbaq_pertemuan_id', pertemuanId)
          .select('id');
      // Pertemuan boleh saja belum memiliki baris absensi; hasil kosong valid.
      // RLS memutuskan apakah baris yang ada memang boleh dihapus.
      if (result is! List) {
        throw Exception('Respons penghapusan absensi tidak valid.');
      }
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus absensi pertemuan BBAQ: ${e.message}');
    }
  }
}
