const Object _unset = Object();

class BbaqPertemuanModel {
  final String id;
  final String programId;

  /// Nullable untuk mempertahankan kompatibilitas data pertemuan lama.
  final String? kelasPengajaranId;

  final DateTime tanggal;
  final String? pengajarId;
  final String? penggantiPengajarId;
  final String? materiPembelajaran;
  final String metode;
  final String? createdBy;
  final DateTime createdAt;

  final String? namaPengajar;
  final String? namaPenggantiPengajar;

  const BbaqPertemuanModel({
    required this.id,
    required this.programId,
    this.kelasPengajaranId,
    required this.tanggal,
    this.pengajarId,
    this.penggantiPengajarId,
    this.materiPembelajaran,
    required this.metode,
    this.createdBy,
    required this.createdAt,
    this.namaPengajar,
    this.namaPenggantiPengajar,
  });

  factory BbaqPertemuanModel.fromJson(Map<String, dynamic> json) {
    final pengajar = json['pengajar'];
    final penggantiPengajar = json['pengganti_pengajar'];

    return BbaqPertemuanModel(
      id: json['id']?.toString() ?? '',
      programId: json['program_id']?.toString() ?? '',
      kelasPengajaranId: json['kelas_pengajaran_id']?.toString(),
      tanggal: DateTime.parse(json['tanggal'].toString()),
      pengajarId: json['pengajar_id']?.toString(),
      penggantiPengajarId: json['pengganti_pengajar_id']?.toString(),
      materiPembelajaran: json['materi_pembelajaran']?.toString(),
      metode: json['metode']?.toString() ?? 'Offline',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      namaPengajar: pengajar is Map ? pengajar['username']?.toString() : null,
      namaPenggantiPengajar: penggantiPengajar is Map
          ? penggantiPengajar['nama']?.toString()
          : null,
    );
  }

  // ============================================================
  // JSON INSERT
  // ============================================================

  Map<String, dynamic> toInsertJson() {
    return {
      'program_id': programId,
      'kelas_pengajaran_id': kelasPengajaranId,
      'tanggal': _formatDate(tanggal),
      'pengajar_id': pengajarId,
      'pengganti_pengajar_id': penggantiPengajarId,
      'materi_pembelajaran': materiPembelajaran,
      'metode': metode,
      'created_by': createdBy,
    };
  }

  // ============================================================
  // JSON UPDATE
  // ============================================================

  Map<String, dynamic> toUpdateJson() {
    return {
      'kelas_pengajaran_id': kelasPengajaranId,
      'tanggal': _formatDate(tanggal),
      'pengajar_id': pengajarId,
      'pengganti_pengajar_id': penggantiPengajarId,
      'materi_pembelajaran': materiPembelajaran,
      'metode': metode,
    };
  }

  // ============================================================
  // BATAS WAKTU ABSENSI
  // ============================================================

  /// Waktu acuan adalah bbaq_pertemuan.created_at.
  ///
  /// Timestamp dari Supabase diparsing sebagai DateTime lalu
  /// dikonversi ke waktu lokal untuk tampilan dan perhitungan.
  DateTime get batasAbsensi {
    return createdAt.toLocal().add(const Duration(hours: 24));
  }

  bool get canInputAbsensi {
    return DateTime.now().isBefore(batasAbsensi);
  }

  /// Alias agar pemanggil lama yang menggunakan canEdit tetap bekerja.
  bool get canEdit => canInputAbsensi;

  Duration get remainingAbsensiTime {
    final remaining = batasAbsensi.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get remainingEditTime => remainingAbsensiTime;

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  /// Field nullable dapat dipertahankan, diubah, atau dikosongkan.
  ///
  /// Contoh:
  /// copyWith(clearPenggantiPengajarId: true)
  /// akan mengosongkan penggantiPengajarId.
  BbaqPertemuanModel copyWith({
    String? id,
    String? programId,
    Object? kelasPengajaranId = _unset,
    DateTime? tanggal,
    Object? pengajarId = _unset,
    Object? penggantiPengajarId = _unset,
    Object? materiPembelajaran = _unset,
    String? metode,
    Object? createdBy = _unset,
    DateTime? createdAt,
    Object? namaPengajar = _unset,
    Object? namaPenggantiPengajar = _unset,
    bool clearKelasPengajaranId = false,
    bool clearPengajarId = false,
    bool clearPenggantiPengajarId = false,
    bool clearMateriPembelajaran = false,
    bool clearCreatedBy = false,
    bool clearNamaPengajar = false,
    bool clearNamaPenggantiPengajar = false,
  }) {
    return BbaqPertemuanModel(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      kelasPengajaranId: clearKelasPengajaranId
          ? null
          : identical(kelasPengajaranId, _unset)
          ? this.kelasPengajaranId
          : kelasPengajaranId as String?,
      tanggal: tanggal ?? this.tanggal,
      pengajarId: clearPengajarId
          ? null
          : identical(pengajarId, _unset)
          ? this.pengajarId
          : pengajarId as String?,
      penggantiPengajarId: clearPenggantiPengajarId
          ? null
          : identical(penggantiPengajarId, _unset)
          ? this.penggantiPengajarId
          : penggantiPengajarId as String?,
      materiPembelajaran: clearMateriPembelajaran
          ? null
          : identical(materiPembelajaran, _unset)
          ? this.materiPembelajaran
          : materiPembelajaran as String?,
      metode: metode ?? this.metode,
      createdBy: clearCreatedBy
          ? null
          : identical(createdBy, _unset)
          ? this.createdBy
          : createdBy as String?,
      createdAt: createdAt ?? this.createdAt,
      namaPengajar: clearNamaPengajar
          ? null
          : identical(namaPengajar, _unset)
          ? this.namaPengajar
          : namaPengajar as String?,
      namaPenggantiPengajar: clearNamaPenggantiPengajar
          ? null
          : identical(namaPenggantiPengajar, _unset)
          ? this.namaPenggantiPengajar
          : namaPenggantiPengajar as String?,
    );
  }
}
