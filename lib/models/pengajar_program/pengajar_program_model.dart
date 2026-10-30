class PengajarProgramModel {
  final String id;
  final String pengajarId;
  final String programId;
  final DateTime? createdAt;

  // Data relasi
  final String? namaPengajar;
  final String? namaProgram;

  PengajarProgramModel({
    required this.id,
    required this.pengajarId,
    required this.programId,
    this.createdAt,
    this.namaPengajar,
    this.namaProgram,
  });

  factory PengajarProgramModel.fromMap(Map<String, dynamic> map) {
    final pengajar = map['pengajar'];
    final program = map['program'];

    return PengajarProgramModel(
      id: map['id']?.toString() ?? '',
      pengajarId: map['pengajar_id']?.toString() ?? '',
      programId: map['program_id']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      namaPengajar: pengajar is Map
          ? pengajar['username']?.toString()
          : null,
      namaProgram: program is Map
          ? program['nama']?.toString()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pengajar_id': pengajarId,
      'program_id': programId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'pengajar_id': pengajarId,
      'program_id': programId,
    };
  }

  PengajarProgramModel copyWith({
    String? id,
    String? pengajarId,
    String? programId,
    DateTime? createdAt,
    String? namaPengajar,
    String? namaProgram,
  }) {
    return PengajarProgramModel(
      id: id ?? this.id,
      pengajarId: pengajarId ?? this.pengajarId,
      programId: programId ?? this.programId,
      createdAt: createdAt ?? this.createdAt,
      namaPengajar: namaPengajar ?? this.namaPengajar,
      namaProgram: namaProgram ?? this.namaProgram,
    );
  }
}