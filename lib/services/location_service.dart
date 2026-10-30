import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class LocationService {
  static const String _baseUrl = 'https://api.myquran.com/v2/sholat';
  static const Duration _timeout = Duration(seconds: 10);

  // Cache lokal seluruh daftar kota di Indonesia
  List<CityLocation>? _cachedCities;

  // ============================================================
  // SEARCH LOKASI (Kota/Kabupaten)
  // ============================================================
  Future<List<CityLocation>> searchLocations(String query) async {
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.length < 2) {
      return [];
    }

    try {
      // Fetch daftar semua kota jika cache masih kosong (Hanya 1x call API)
      if (_cachedCities == null) {
        final uri = Uri.parse('$_baseUrl/kota/semua');
        final response = await http.get(uri).timeout(_timeout);

        if (response.statusCode != 200) {
          throw LocationApiException('Gagal memuat data kota dari server.');
        }

        final decoded = jsonDecode(response.body);
        if (decoded['status'] == true && decoded['data'] != null) {
          final List data = decoded['data'];
          _cachedCities = data.map((e) => CityLocation.fromJson(e)).toList();
        } else {
          throw LocationApiException('Format respon API tidak valid.');
        }
      }

      // Filter berdasarkan kata kunci pengguna
      return _cachedCities!
          .where((city) => city.name.toLowerCase().contains(cleanQuery))
          .toList();
    } on TimeoutException {
      throw LocationTimeoutException(
        'Koneksi ke server jadwal sholat waktu habis.',
      );
    } on SocketException catch (e) {
      throw LocationNetworkException(
        'Periksa koneksi internet Anda: ${e.message}',
      );
    } catch (e) {
      throw LocationApiException('Gagal mencari lokasi: $e');
    }
  }

  // ============================================================
  // GET JADWAL SHOLAT BERDASARKAN ID KOTA & TANGGAL
  // ============================================================
  Future<JadwalSholatModel> getJadwalSholat({
    required String cityId,
    required DateTime date,
  }) async {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    final uri = Uri.parse('$_baseUrl/jadwal/$cityId/$year/$month/$day');

    try {
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw LocationApiException('Gagal mengambil jadwal sholat.');
      }

      final decoded = jsonDecode(response.body);
      if (decoded['status'] == true && decoded['data']?['jadwal'] != null) {
        return JadwalSholatModel.fromJson(decoded['data']['jadwal']);
      } else {
        throw LocationApiException('Data jadwal sholat tidak ditemukan.');
      }
    } on TimeoutException {
      throw LocationTimeoutException('Waktu memuat jadwal sholat habis.');
    } on SocketException {
      throw LocationNetworkException('Tidak ada koneksi internet.');
    } catch (e) {
      throw LocationApiException('Terjadi kesalahan: $e');
    }
  }
}

// Exception Classes
class LocationApiException implements Exception {
  final String message;
  LocationApiException(this.message);
  @override
  String toString() => message;
}

class LocationNetworkException implements Exception {
  final String message;
  LocationNetworkException(this.message);
  @override
  String toString() => message;
}

class LocationTimeoutException implements Exception {
  final String message;
  LocationTimeoutException(this.message);
  @override
  String toString() => message;
}
