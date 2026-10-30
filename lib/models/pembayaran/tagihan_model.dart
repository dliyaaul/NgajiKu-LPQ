class TagihanItemModel {
  final String id;
  final String tagihanId;
  final String deskripsi;
  final String jenis;
  final String? referensiId;
  final DateTime? tanggal;
  final double jumlah;
  final String satuan;
  final double hargaSatuan;
  final double subtotal;
  final Map<String, dynamic>? metadata;

  const TagihanItemModel({
    required this.id,
    required this.tagihanId,
    required this.deskripsi,
    required this.jenis,
    this.referensiId,
    this.tanggal,
    required this.jumlah,
    required this.satuan,
    required this.hargaSatuan,
    required this.subtotal,
    this.metadata,
  });

  factory TagihanItemModel.fromJson(Map<String, dynamic> json) {
    return TagihanItemModel(
      id: json['id'].toString(),
      tagihanId: json['tagihan_id'].toString(),
      deskripsi: json['deskripsi'] as String? ?? '-',
      jenis: json['jenis'] as String? ?? 'pertemuan',
      referensiId: json['referensi_id']?.toString(),
      tanggal: json['tanggal'] == null
          ? null
          : DateTime.tryParse(json['tanggal'].toString()),
      jumlah: _toDouble(json['jumlah']),
      satuan: json['satuan'] as String? ?? 'pertemuan',
      hargaSatuan: _toDouble(json['harga_satuan']),
      subtotal: _toDouble(json['subtotal']),
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TagihanModel {
  final String id;
  final String nomorTagihan;
  final String tipePembayar;
  final String? santriProgramId;
  final String? lembagaId;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;
  final DateTime tanggalTagihan;
  final DateTime? tanggalJatuhTempo;
  final double subtotal;
  final double diskon;
  final double total;
  final String status;
  final DateTime? createdAt;
  final List<TagihanItemModel> items;
  final String? namaSantri;
  final String? namaProgram;
  final String? namaLembaga;

  const TagihanModel({
    required this.id,
    required this.nomorTagihan,
    required this.tipePembayar,
    this.santriProgramId,
    this.lembagaId,
    required this.periodeMulai,
    required this.periodeSelesai,
    required this.tanggalTagihan,
    this.tanggalJatuhTempo,
    required this.subtotal,
    required this.diskon,
    required this.total,
    required this.status,
    this.createdAt,
    this.items = const [],
    this.namaSantri,
    this.namaProgram,
    this.namaLembaga,
  });

  factory TagihanModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['tagihan_item'] as List? ?? [];
    final rawSantriProgram = json['santri_programs'];

    final santriProgram = rawSantriProgram is Map
        ? Map<String, dynamic>.from(rawSantriProgram)
        : <String, dynamic>{};

    final rawProfil = santriProgram['profiles'];
    final profil = rawProfil is Map
        ? Map<String, dynamic>.from(rawProfil)
        : <String, dynamic>{};

    final rawProgram = santriProgram['programs'];
    final program = rawProgram is Map
        ? Map<String, dynamic>.from(rawProgram)
        : <String, dynamic>{};

    final rawLembaga = json['lembaga'];
    final lembaga = rawLembaga is Map
        ? Map<String, dynamic>.from(rawLembaga)
        : <String, dynamic>{};
    return TagihanModel(
      id: json['id'].toString(),
      nomorTagihan: json['nomor_tagihan'] as String? ?? '-',
      tipePembayar: json['tipe_pembayar'] as String? ?? 'santri',
      santriProgramId: json['santri_program_id']?.toString(),
      lembagaId: json['lembaga_id']?.toString(),
      periodeMulai: DateTime.parse(json['periode_mulai'].toString()),
      periodeSelesai: DateTime.parse(json['periode_selesai'].toString()),
      tanggalTagihan: DateTime.parse(json['tanggal_tagihan'].toString()),
      tanggalJatuhTempo: json['tanggal_jatuh_tempo'] == null
          ? null
          : DateTime.tryParse(json['tanggal_jatuh_tempo'].toString()),
      subtotal: _toDouble(json['subtotal']),
      diskon: _toDouble(json['diskon']),
      total: _toDouble(json['total']),
      status: json['status'] as String? ?? 'belum_bayar',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      items: rawItems
          .map(
            (item) => TagihanItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),  
          )
          .toList(),
      namaSantri: profil['username']?.toString(),
      namaProgram: program['nama']?.toString(),
      namaLembaga: lembaga['nama_lembaga']?.toString(),
    );
  }

  bool get bisaDibayar => status == 'belum_bayar' || status == 'ditolak';

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
