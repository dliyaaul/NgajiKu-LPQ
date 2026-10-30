import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quran/ayat_model.dart';
import '../models/quran/surah_model.dart';

class QuranService {
  static const String baseUrl = 'https://equran.id/api/v2';

  // ============================================================
  // DAFTAR SURAH
  // ============================================================

  Future<List<SurahModel>> getSurahList() async {
    final uri = Uri.parse('$baseUrl/surat');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('====================================');
      print('EQURAN - DAFTAR SURAH');
      print('URL    : $uri');
      print('STATUS : ${response.statusCode}');
      print('====================================');

      if (response.statusCode != 200) {
        print('BODY: ${response.body}');

        throw Exception(
          'Gagal mengambil daftar surah '
          '(HTTP ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response daftar surah tidak valid.');
      }

      final data = decoded['data'];

      if (data is! List) {
        throw Exception('Data daftar surah tidak ditemukan.');
      }

      return data
          .map((item) => SurahModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('EQURAN ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // DETAIL SURAH + AYAT
  // ============================================================

  Future<List<AyatModel>> getAyatBySurah(int nomorSurah) async {
    final uri = Uri.parse('$baseUrl/surat/$nomorSurah');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('====================================');
      print('EQURAN - DETAIL SURAH');
      print('SURAH  : $nomorSurah');
      print('URL    : $uri');
      print('STATUS : ${response.statusCode}');
      print('====================================');

      if (response.statusCode != 200) {
        print('BODY: ${response.body}');

        throw Exception(
          'Gagal mengambil ayat '
          '(HTTP ${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response detail surah tidak valid.');
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Data detail surah tidak ditemukan.');
      }

      final ayatData = data['ayat'];

      if (ayatData is! List) {
        throw Exception('Data ayat tidak ditemukan.');
      }

      return ayatData
          .map((item) => AyatModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('EQURAN ERROR: $e');
      rethrow;
    }
  }
}
