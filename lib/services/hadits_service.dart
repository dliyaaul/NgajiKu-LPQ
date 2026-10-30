import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hadits/hadits_book_model.dart';

class HaditsService {
  static const String baseUrl = 'https://api.housemuslim.org/api/v1';

  Future<List<HaditsBookModel>> getHaditsBooks() async {
    final uri = Uri.parse('$baseUrl/hadith/books');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar kitab hadits '
        '(HTTP ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format response daftar kitab hadits tidak valid.');
    }

    if (decoded['success'] != true) {
      throw Exception('API mengembalikan response gagal.');
    }

    final data = decoded['data'];

    if (data is! List) {
      throw Exception('Data daftar kitab hadits tidak ditemukan.');
    }

    return data
        .map(
          (item) => HaditsBookModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
