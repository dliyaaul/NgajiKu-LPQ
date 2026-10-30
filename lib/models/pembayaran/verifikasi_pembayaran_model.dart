class VerifikasiPembayaranModel {
  final String id;
  final String nomorPembayaran;
  final String tagihanId;
  final String rekeningTujuanId;
  final DateTime tanggalTransfer;
  final num nominalTransfer;
  final String? rekeningPengirim;
  final String? namaPengirim;
  final String buktiTransfer;
  final String? catatan;
  final String status;
  final DateTime? createdAt;

  final String nomorTagihan;
  final num totalTagihan;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;

  final String namaBank;
  final String nomorRekening;
  final String namaPemilik;

  const VerifikasiPembayaranModel({
    required this.id,
    required this.nomorPembayaran,
    required this.tagihanId,
    required this.rekeningTujuanId,
    required this.tanggalTransfer,
    required this.nominalTransfer,
    this.rekeningPengirim,
    this.namaPengirim,
    required this.buktiTransfer,
    this.catatan,
    required this.status,
    this.createdAt,
    required this.nomorTagihan,
    required this.totalTagihan,
    required this.periodeMulai,
    required this.periodeSelesai,
    required this.namaBank,
    required this.nomorRekening,
    required this.namaPemilik,
  });

  factory VerifikasiPembayaranModel.fromJson(Map<String, dynamic> json) {
    final tagihan = Map<String, dynamic>.from(json['tagihan'] as Map);
    final rekening = Map<String, dynamic>.from(json['rekening'] as Map);

    return VerifikasiPembayaranModel(
      id: json['id'].toString(),
      nomorPembayaran: json['nomor_pembayaran'] as String,
      tagihanId: json['tagihan_id'].toString(),
      rekeningTujuanId: json['rekening_tujuan_id'].toString(),
      tanggalTransfer: DateTime.parse(json['tanggal_transfer'].toString()),
      nominalTransfer: json['nominal_transfer'] as num,
      rekeningPengirim: json['rekening_pengirim'] as String?,
      namaPengirim: json['nama_pengirim'] as String?,
      buktiTransfer: json['bukti_transfer'] as String,
      catatan: json['catatan'] as String?,
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'].toString()),
      nomorTagihan: tagihan['nomor_tagihan'] as String,
      totalTagihan: tagihan['total'] as num,
      periodeMulai: DateTime.parse(tagihan['periode_mulai'].toString()),
      periodeSelesai: DateTime.parse(tagihan['periode_selesai'].toString()),
      namaBank: rekening['nama_bank'] as String,
      nomorRekening: rekening['nomor_rekening'] as String,
      namaPemilik: rekening['nama_pemilik'] as String,
    );
  }
}
