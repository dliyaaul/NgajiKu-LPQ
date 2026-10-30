class KelasPengajaranModel {
  final String id;
  final String programId;
  final String kelasTypeId;
  final String namaKelas;
  final String? pengajarId;
  final String? lembagaId;
  final bool aktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nama dari tabel relasi untuk kebutuhan tampilan.
  final String? namaProgram;
  final String? namaJenisKelas;
  final String? namaPengajar;

  const KelasPengajaranModel({
    required this.id,
    required this.programId,
    required this.kelasTypeId,
    required this.namaKelas,
    this.pengajarId,
    this.lembagaId,
    this.aktif = true,
    this.createdAt,
    this.updatedAt,
    this.namaProgram,
    this.namaJenisKelas,
    this.namaPengajar,
  });

  factory KelasPengajaranModel.fromMap(Map<String, dynamic> map) {
    String? relationName(String key) {
      final value = map[key];

      if (value is Map) {
        return (value['nama'] ?? value['username'])?.toString();
      }

      if (value is List && value.isNotEmpty && value.first is Map) {
        final first = value.first;
        return (first['nama'] ?? first['username'])?.toString();
      }

      return null;
    }

    return KelasPengajaranModel(
      id: map['id'].toString(),
      programId: map['program_id'].toString(),
      kelasTypeId: map['kelas_type_id'].toString(),
      namaKelas: (map['nama_kelas'] ?? '').toString(),
      pengajarId: map['pengajar_id']?.toString(),
      lembagaId: map['lembaga_id']?.toString(),
      aktif: map['aktif'] as bool? ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      namaProgram: relationName('programs'),
      namaJenisKelas: relationName('kelas_types'),
      namaPengajar: relationName('pengajar'),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'program_id': programId,
    'kelas_type_id': kelasTypeId,
    'nama_kelas': namaKelas,
    'pengajar_id': pengajarId,
    'lembaga_id': lembagaId,
    'aktif': aktif,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
