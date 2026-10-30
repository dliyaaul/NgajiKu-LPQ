class LembagaModel {
  final String id;
  final String namaLembaga;
  final String pbmType;
  final String? alamat;
  final String? programId;
  final String? pengajarId;
  final DateTime? createdAt;

  LembagaModel({
    required this.id,
    required this.namaLembaga,
    required this.pbmType,
    this.alamat,
    this.programId,
    this.pengajarId,
    this.createdAt,
  });

  factory LembagaModel.fromMap(Map<String, dynamic> map) {
    return LembagaModel(
      id: map['id'] as String,
      namaLembaga: map['nama_lembaga'] as String,
      pbmType: map['pbm_type'] as String,
      alamat: map['alamat'] as String?,
      programId: map['program_id'] as String?,
      pengajarId: map['pengajar_id'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_lembaga': namaLembaga,
      'pbm_type': pbmType,
      'alamat': alamat,
      'program_id': programId,
      'pengajar_id': pengajarId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
