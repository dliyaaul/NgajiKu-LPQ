class AbsensiTahfidzModel {
  final String id;

  /// ID pertemuan Tahfidz.
  ///
  /// Setiap data absensi wajib terhubung ke satu pertemuan.
  final String tahfidzPertemuanId;

  /// ID relasi santri_programs.
  final String santriProgramId;

  /// Tanggal pertemuan.
  ///
  /// Tetap disimpan pada model untuk kebutuhan tampilan,
  /// rekap lama, atau kompatibilitas dengan data sebelumnya.
  final DateTime tanggal;

  /// Status absensi:
  /// Hadir | Izin | Sakit | Alpha
  final String status;

  /// Jenis hafalan:
  /// - Baru
  /// - Murajaah
  /// dan nilai lain sesuai kebutuhan aplikasi.
  final String? jenisTahfidz;

  /// Nama surat yang dihafalkan.
  final String? surat;

  /// Ayat awal.
  final int? ayatMulai;

  /// Ayat akhir.
  final int? ayatSelesai;

  /// Keterangan tambahan.
  final String? keterangan;

  final String? createdBy;
  final DateTime? createdAt;

  const AbsensiTahfidzModel({
    required this.id,
    required this.tahfidzPertemuanId,
    required this.santriProgramId,
    required this.tanggal,
    required this.status,
    this.jenisTahfidz,
    this.surat,
    this.ayatMulai,
    this.ayatSelesai,
    this.keterangan,
    this.createdBy,
    this.createdAt,
  });

  // ================================================================
  // FROM MAP
  // ================================================================

  factory AbsensiTahfidzModel.fromMap(Map<String, dynamic> map) {
    return AbsensiTahfidzModel(
      id: map['id']?.toString() ?? '',

      tahfidzPertemuanId: map['tahfidz_pertemuan_id']?.toString() ?? '',

      santriProgramId: map['santri_program_id']?.toString() ?? '',

      tanggal: _parseDate(map['tanggal']),

      status: map['status']?.toString() ?? 'Alpha',

      jenisTahfidz: map['jenis_tahfidz']?.toString(),

      surat: map['surat']?.toString(),

      ayatMulai: _parseInt(map['ayat_mulai']),

      ayatSelesai: _parseInt(map['ayat_selesai']),

      keterangan: map['keterangan']?.toString(),

      createdBy: map['created_by']?.toString(),

      createdAt: _parseNullableDateTime(map['created_at']),
    );
  }

  // ================================================================
  // TO MAP
  // ================================================================

  Map<String, dynamic> toMap({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    final map = <String, dynamic>{
      'tahfidz_pertemuan_id': tahfidzPertemuanId,
      'santri_program_id': santriProgramId,
      'tanggal': _formatDate(tanggal),
      'status': status,
      'jenis_tahfidz': jenisTahfidz,
      'surat': surat,
      'ayat_mulai': ayatMulai,
      'ayat_selesai': ayatSelesai,
      'keterangan': keterangan,
      'created_by': createdBy,
    };

    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }

    if (includeCreatedAt && createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }

    return map;
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  AbsensiTahfidzModel copyWith({
    String? id,
    String? tahfidzPertemuanId,
    String? santriProgramId,
    DateTime? tanggal,
    String? status,
    String? jenisTahfidz,
    String? surat,
    int? ayatMulai,
    int? ayatSelesai,
    String? keterangan,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return AbsensiTahfidzModel(
      id: id ?? this.id,

      tahfidzPertemuanId: tahfidzPertemuanId ?? this.tahfidzPertemuanId,

      santriProgramId: santriProgramId ?? this.santriProgramId,

      tanggal: tanggal ?? this.tanggal,

      status: status ?? this.status,

      jenisTahfidz: jenisTahfidz ?? this.jenisTahfidz,

      surat: surat ?? this.surat,

      ayatMulai: ayatMulai ?? this.ayatMulai,

      ayatSelesai: ayatSelesai ?? this.ayatSelesai,

      keterangan: keterangan ?? this.keterangan,

      createdBy: createdBy ?? this.createdBy,

      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ================================================================
  // DISPLAY HELPERS
  // ================================================================

  /// Menampilkan rentang ayat.
  ///
  /// Contoh:
  /// 1 - 5
  /// 10
  String get ayatDisplay {
    if (ayatMulai == null && ayatSelesai == null) {
      return '';
    }

    if (ayatMulai != null && ayatSelesai != null) {
      if (ayatMulai == ayatSelesai) {
        return '$ayatMulai';
      }

      return '$ayatMulai - $ayatSelesai';
    }

    return (ayatMulai ?? ayatSelesai).toString();
  }

  /// Menampilkan informasi hafalan.
  ///
  /// Contoh:
  /// Ziyadah • Al-Baqarah • 1 - 5
  String get tahfidzDisplay {
    final parts = <String>[];

    if (jenisTahfidz != null && jenisTahfidz!.trim().isNotEmpty) {
      parts.add(jenisTahfidz!.trim());
    }

    if (surat != null && surat!.trim().isNotEmpty) {
      parts.add(surat!.trim());
    }

    if (ayatDisplay.isNotEmpty) {
      parts.add(ayatDisplay);
    }

    return parts.join(' • ');
  }

  /// Apakah santri hadir.
  bool get isHadir => status == 'Hadir';

  /// Apakah santri belum hadir.
  bool get isBelumAbsen => status == 'Belum Absen';

  /// Apakah data hafalan tersedia.
  bool get hasTahfidzData {
    return (jenisTahfidz != null && jenisTahfidz!.trim().isNotEmpty) ||
        (surat != null && surat!.trim().isNotEmpty) ||
        ayatMulai != null ||
        ayatSelesai != null;
  }

  // ================================================================
  // PARSER
  // ================================================================

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text = value?.toString();

    if (text == null || text.isEmpty) {
      return DateTime.now();
    }

    try {
      return DateTime.parse(text);
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final text = value.toString();

    if (text.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  // ================================================================
  // DATE FORMAT
  // ================================================================

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ================================================================
  // DEBUG
  // ================================================================

  @override
  String toString() {
    return 'AbsensiTahfidzModel('
        'id: $id, '
        'tahfidzPertemuanId: $tahfidzPertemuanId, '
        'santriProgramId: $santriProgramId, '
        'tanggal: $tanggal, '
        'status: $status, '
        'jenisTahfidz: $jenisTahfidz, '
        'surat: $surat, '
        'ayatMulai: $ayatMulai, '
        'ayatSelesai: $ayatSelesai, '
        'keterangan: $keterangan'
        ')';
  }
}
