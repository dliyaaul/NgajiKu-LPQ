class SurahModel {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi;
  final Map<String, dynamic> audioFull;

  const SurahModel({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.audioFull,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      nomor: json['nomor'] ?? 0,
      nama: json['nama'] ?? '',
      namaLatin: json['namaLatin'] ?? '',
      jumlahAyat: json['jumlahAyat'] ?? 0,
      tempatTurun: json['tempatTurun'] ?? '',
      arti: json['arti'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      audioFull: json['audioFull'] is Map
          ? Map<String, dynamic>.from(json['audioFull'])
          : {},
    );
  }

  String getAudioFullUrl([String qariId = '05']) {
    final value = audioFull[qariId];

    if (value is String) {
      return value;
    }

    return '';
  }
}
