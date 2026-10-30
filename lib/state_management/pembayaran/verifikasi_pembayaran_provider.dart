import 'package:flutter/foundation.dart';

import '../../models/pembayaran/verifikasi_pembayaran_model.dart';
import '../../services/pembayaran/verifikasi_pembayaran_service.dart';

class VerifikasiPembayaranProvider extends ChangeNotifier {
  final VerifikasiPembayaranService _service = VerifikasiPembayaranService();

  List<VerifikasiPembayaranModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VerifikasiPembayaranModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getMenungguVerifikasi();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getUrlBuktiTransfer(String path) {
    return _service.getUrlBuktiTransfer(path);
  }

  Future<void> verifikasi({
    required String pembayaranId,
    required String statusBaru,
    String? catatan,
  }) async {
    await _service.verifikasi(
      pembayaranId: pembayaranId,
      statusBaru: statusBaru,
      catatan: catatan,
    );

    await loadData();

    if (_errorMessage != null) {
      throw Exception(
        'Verifikasi berhasil, tetapi daftar pembayaran gagal dimuat ulang: $_errorMessage',
      );
    }
  }
}
