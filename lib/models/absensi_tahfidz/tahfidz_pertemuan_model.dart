import 'package:intl/intl.dart';

class TahfidzPertemuanModel {
  final String id;
  final String programId;

  // Relasi kelas pengajaran
  final String kelasPengajaranId;

  final DateTime tanggal;
  final String? pengajarId;
  final String? penggantiPengajarId;
  final String? materiPembelajaran;
  final String metode;
  final String? createdBy;
  final DateTime createdAt;

  // Relational data
  final String? namaPengajar;
  final String? namaPenggantiPengajar;
  final String? namaProgram;
  final String? namaKelasPengajaran;

  const TahfidzPertemuanModel({
    required this.id,
    required this.programId,
    required this.kelasPengajaranId,
    required this.tanggal,
    this.pengajarId,
    this.penggantiPengajarId,
    this.materiPembelajaran,
    required this.metode,
    this.createdBy,
    required this.createdAt,
    this.namaPengajar,
    this.namaPenggantiPengajar,
    this.namaProgram,
    this.namaKelasPengajaran,
  });

  // ==========================================================================
  // FROM MAP
  // ==========================================================================

  factory TahfidzPertemuanModel.fromMap(Map<String, dynamic> map) {
    String? extractName(dynamic value) {
      if (value is Map) {
        return value['username']?.toString() ??
            value['nama']?.toString() ??
            value['name']?.toString();
      }

      if (value is List && value.isNotEmpty) {
        final first = value.first;

        if (first is Map) {
          return first['username']?.toString() ??
              first['nama']?.toString() ??
              first['name']?.toString();
        }
      }

      return null;
    }

    return TahfidzPertemuanModel(
      id: map['id']?.toString() ?? '',
      programId: map['program_id']?.toString() ?? '',

      kelasPengajaranId: map['kelas_pengajaran_id']?.toString() ?? '',

      tanggal: _parseDate(map['tanggal']),

      pengajarId: map['pengajar_id']?.toString(),

      penggantiPengajarId: map['pengganti_pengajar_id']?.toString(),

      materiPembelajaran: map['materi_pembelajaran']?.toString(),

      metode: map['metode']?.toString() ?? 'Offline',

      createdBy: map['created_by']?.toString(),

      createdAt: _parseDateTime(map['created_at']),

      namaPengajar: extractName(map['pengajar']),

      namaPenggantiPengajar: extractName(map['pengganti_pengajar']),

      namaProgram: extractName(map['program']),

      namaKelasPengajaran: extractName(map['kelas_pengajaran']),
    );
  }

  // ==========================================================================
  // TO MAP
  // ==========================================================================

  Map<String, dynamic> toMap({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    final map = <String, dynamic>{
      'program_id': programId,

      'kelas_pengajaran_id': kelasPengajaranId,

      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),

      'pengajar_id': pengajarId,

      'pengganti_pengajar_id': penggantiPengajarId,

      'materi_pembelajaran': materiPembelajaran,

      'metode': metode,

      'created_by': createdBy,
    };

    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }

    if (includeCreatedAt) {
      map['created_at'] = createdAt.toIso8601String();
    }

    return map;
  }

  // ==========================================================================
  // DATE FORMATTING
  // ==========================================================================

  String get tanggalFormatted {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(tanggal);
  }

  // ==========================================================================
  // SUBSTITUTE TEACHER
  // ==========================================================================

  bool get menggunakanPengganti {
    return penggantiPengajarId != null && penggantiPengajarId!.isNotEmpty;
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  TahfidzPertemuanModel copyWith({
    String? id,
    String? programId,
    String? kelasPengajaranId,
    DateTime? tanggal,
    String? pengajarId,
    String? penggantiPengajarId,
    String? materiPembelajaran,
    String? metode,
    String? createdBy,
    DateTime? createdAt,
    String? namaPengajar,
    String? namaPenggantiPengajar,
    String? namaProgram,
    String? namaKelasPengajaran,
  }) {
    return TahfidzPertemuanModel(
      id: id ?? this.id,
      programId: programId ?? this.programId,

      kelasPengajaranId: kelasPengajaranId ?? this.kelasPengajaranId,

      tanggal: tanggal ?? this.tanggal,
      pengajarId: pengajarId ?? this.pengajarId,
      penggantiPengajarId: penggantiPengajarId ?? this.penggantiPengajarId,
      materiPembelajaran: materiPembelajaran ?? this.materiPembelajaran,
      metode: metode ?? this.metode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      namaPengajar: namaPengajar ?? this.namaPengajar,
      namaPenggantiPengajar:
          namaPenggantiPengajar ?? this.namaPenggantiPengajar,
      namaProgram: namaProgram ?? this.namaProgram,
      namaKelasPengajaran: namaKelasPengajaran ?? this.namaKelasPengajaran,
    );
  }

  // ==========================================================================
  // PRIVATE PARSERS
  // ==========================================================================

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text = value?.toString();

    if (text == null || text.isEmpty) {
      return DateTime.now();
    }

    return DateTime.parse(text);
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text = value?.toString();

    if (text == null || text.isEmpty) {
      return DateTime.now();
    }

    return DateTime.parse(text);
  }
}
