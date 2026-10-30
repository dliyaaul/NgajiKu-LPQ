class PembayaranTarifModel {
  final String id;
  final String namaTarif;
  final String kelasTypeId;
  final String? programId;
  final String? santriProgramId;
  final String? lembagaId;
  final num nominal;
  final String satuan;
  final DateTime berlakuMulai;
  final DateTime? berlakuSampai;
  final bool aktif;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PembayaranTarifModel({
    required this.id,
    required this.namaTarif,
    required this.kelasTypeId,
    this.programId,
    this.santriProgramId,
    this.lembagaId,
    required this.nominal,
    required this.satuan,
    required this.berlakuMulai,
    this.berlakuSampai,
    required this.aktif,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PembayaranTarifModel.fromJson(Map<String, dynamic> json) {
    return PembayaranTarifModel(
      id: json['id'].toString(),
      namaTarif: json['nama_tarif'] as String,
      kelasTypeId: json['kelas_type_id'].toString(),
      programId: json['program_id']?.toString(),
      santriProgramId: json['santri_program_id']?.toString(),
      lembagaId: json['lembaga_id']?.toString(),
      nominal: json['nominal'] as num,
      satuan: json['satuan'] as String,
      berlakuMulai: DateTime.parse(json['berlaku_mulai'].toString()),
      berlakuSampai: json['berlaku_sampai'] == null
          ? null
          : DateTime.parse(json['berlaku_sampai'].toString()),
      aktif: json['aktif'] as bool? ?? true,
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_tarif': namaTarif,
      'kelas_type_id': kelasTypeId,
      'program_id': programId,
      'santri_program_id': santriProgramId,
      'lembaga_id': lembagaId,
      'nominal': nominal,
      'satuan': satuan,
      'berlaku_mulai': _formatDate(berlakuMulai),
      'berlaku_sampai': berlakuSampai == null
          ? null
          : _formatDate(berlakuSampai!),
      'aktif': aktif,
    };
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
