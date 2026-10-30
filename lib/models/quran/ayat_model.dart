class AyatModel {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;

  const AyatModel({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
  });

  factory AyatModel.fromJson(Map<String, dynamic> json) {
    return AyatModel(
      nomorAyat: json['nomorAyat'] ?? 0,

      // Pastikan hanya mengambil teksArab
      teksArab: _parseString(json['teksArab']),

      teksLatin: _parseString(json['teksLatin']),

      teksIndonesia: _parseString(json['teksIndonesia']),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    return value.toString();
  }
}
