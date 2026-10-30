class PembayaranRekeningModel {
  final String id;
  final String namaBank;
  final String nomorRekening;
  final String namaPemilik;
  final String? keterangan;

  const PembayaranRekeningModel({
    required this.id,
    required this.namaBank,
    required this.nomorRekening,
    required this.namaPemilik,
    this.keterangan,
  });

  factory PembayaranRekeningModel.fromJson(Map<String, dynamic> json) {
    return PembayaranRekeningModel(
      id: json['id'].toString(),
      namaBank: json['nama_bank'] as String? ?? '-',
      nomorRekening: json['nomor_rekening'] as String? ?? '-',
      namaPemilik: json['nama_pemilik'] as String? ?? '-',
      keterangan: json['keterangan'] as String?,
    );
  }
}
