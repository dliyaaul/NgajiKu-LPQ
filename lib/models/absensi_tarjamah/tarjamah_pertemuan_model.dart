class TarjamahPertemuanModel {
  final String id;
  final String programId;
  final String? kelasPengajaranId;
  final DateTime tanggal;

  // PENGAJAR
  final String? pengajarId;
  final String? pengajarPenggantiId;

  // DETAIL PEMBELAJARAN
  final String? materiPembelajaran;
  final String metode;

  // AUDIT
  final String? createdBy;
  final DateTime createdAt;

  // RELATIONAL DATA
  final String? namaPengajar;
  final String? namaPengajarPengganti;

  const TarjamahPertemuanModel({
    required this.id,
    required this.programId,
    this.kelasPengajaranId,
    required this.tanggal,
    this.pengajarId,
    this.pengajarPenggantiId,
    this.materiPembelajaran,
    required this.metode,
    this.createdBy,
    required this.createdAt,
    this.namaPengajar,
    this.namaPengajarPengganti,
  });

  factory TarjamahPertemuanModel.fromJson(Map<String, dynamic> json) {
    final pengajar = json['pengajar'];
    final pengajarPengganti = json['pengajar_pengganti'];

    return TarjamahPertemuanModel(
      id: json['id']?.toString() ?? '',
      programId: json['program_id']?.toString() ?? '',
      kelasPengajaranId: json['kelas_pengajaran_id']?.toString(),
      tanggal: DateTime.parse(json['tanggal'].toString()),
      pengajarId: json['pengajar_id']?.toString(),
      pengajarPenggantiId: json['pengajar_pengganti_id']?.toString(),
      materiPembelajaran: json['materi_pembelajaran']?.toString(),
      metode: json['metode']?.toString() ?? 'Tatap Muka',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
      namaPengajar: pengajar is Map ? pengajar['username']?.toString() : null,
      namaPengajarPengganti: pengajarPengganti is Map
          ? pengajarPengganti['nama']?.toString()
          : null,
    );
  }

  // PENGAJAR AKTIF

  String get pengajarAktifId {
    if (pengajarPenggantiId != null && pengajarPenggantiId!.trim().isNotEmpty) {
      return pengajarPenggantiId!;
    }

    return pengajarId ?? '';
  }

  String get namaPengajarAktif {
    if (namaPengajarPengganti != null &&
        namaPengajarPengganti!.trim().isNotEmpty) {
      return namaPengajarPengganti!;
    }

    return namaPengajar ?? 'Belum dipilih';
  }

  bool get hasPengganti {
    return pengajarPenggantiId != null &&
        pengajarPenggantiId!.trim().isNotEmpty;
  }

  // BATAS WAKTU 24 JAM

  DateTime get batasWaktu {
    return createdAt.add(const Duration(days: 1));
  }

  bool get canEdit {
    return DateTime.now().isBefore(batasWaktu);
  }

  bool get canInputAttendance {
    return DateTime.now().isBefore(batasWaktu);
  }

  bool get isExpired {
    return !DateTime.now().isBefore(batasWaktu);
  }

  Duration get remainingTime {
    final remaining = batasWaktu.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get remainingEditTime => remainingTime;

  Duration get remainingAttendanceTime => remainingTime;

  // INSERT

  Map<String, dynamic> toInsertJson() {
    return {
      'program_id': programId,
      'kelas_pengajaran_id': kelasPengajaranId,
      'tanggal': _formatDate(tanggal),
      'pengajar_id': pengajarId,
      'pengajar_pengganti_id': pengajarPenggantiId,
      'materi_pembelajaran': materiPembelajaran,
      'metode': metode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // UPDATE

  Map<String, dynamic> toUpdateJson() {
    return {
      'program_id': programId,
      'kelas_pengajaran_id': kelasPengajaranId,
      'tanggal': _formatDate(tanggal),
      'pengajar_id': pengajarId,
      'pengajar_pengganti_id': pengajarPenggantiId,
      'materi_pembelajaran': materiPembelajaran,
      'metode': metode,
    };
  }

  // DATE FORMAT

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // COPY WITH

  TarjamahPertemuanModel copyWith({
    String? id,
    String? programId,
    String? kelasPengajaranId,
    DateTime? tanggal,
    String? pengajarId,
    String? pengajarPenggantiId,
    String? materiPembelajaran,
    String? metode,
    String? createdBy,
    DateTime? createdAt,
    String? namaPengajar,
    String? namaPengajarPengganti,
  }) {
    return TarjamahPertemuanModel(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      kelasPengajaranId: kelasPengajaranId ?? this.kelasPengajaranId,
      tanggal: tanggal ?? this.tanggal,
      pengajarId: pengajarId ?? this.pengajarId,
      pengajarPenggantiId: pengajarPenggantiId ?? this.pengajarPenggantiId,
      materiPembelajaran: materiPembelajaran ?? this.materiPembelajaran,
      metode: metode ?? this.metode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      namaPengajar: namaPengajar ?? this.namaPengajar,
      namaPengajarPengganti:
          namaPengajarPengganti ?? this.namaPengajarPengganti,
    );
  }
}
