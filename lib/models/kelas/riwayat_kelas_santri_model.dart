class RiwayatKelasSantriModel {
  final String id;
  final String santriProgramId;
  final String? kelasAsalId;
  final String? kelasTujuanId;
  final DateTime berlakuMulai;
  final DateTime createdAt;
  final String? alasan;
  final String? namaKelasAsal;
  final String? namaKelasTujuan;

  const RiwayatKelasSantriModel({
    required this.id,
    required this.santriProgramId,
    this.kelasAsalId,
    this.kelasTujuanId,
    required this.berlakuMulai,
    required this.createdAt,
    this.alasan,
    this.namaKelasAsal,
    this.namaKelasTujuan,
  });

  factory RiwayatKelasSantriModel.fromMap(Map<String, dynamic> map) {
    final kelasAsal = map['kelas_asal'];
    final kelasTujuan = map['kelas_tujuan'];

    return RiwayatKelasSantriModel(
      id: map['id'].toString(),
      santriProgramId: map['santri_program_id'].toString(),
      kelasAsalId: map['kelas_asal_id']?.toString(),
      kelasTujuanId: map['kelas_tujuan_id']?.toString(),
      berlakuMulai: DateTime.parse(map['berlaku_mulai'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
      alasan: map['alasan']?.toString(),
      namaKelasAsal: kelasAsal is Map
          ? kelasAsal['nama_kelas']?.toString()
          : null,
      namaKelasTujuan: kelasTujuan is Map
          ? kelasTujuan['nama_kelas']?.toString()
          : null,
    );
  }
}
