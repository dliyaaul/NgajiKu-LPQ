import 'package:flutter/foundation.dart';

import '../../models/pembayaran/pembayaran_tarif_model.dart';
import '../../services/pembayaran/pembayaran_tarif_service.dart';

class PembayaranTarifProvider extends ChangeNotifier {
  final PembayaranTarifService _service = PembayaranTarifService();

  List<PembayaranTarifModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PembayaranTarifModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PembayaranTarifModel> get tarifAktif =>
      _items.where((item) => item.aktif).toList();

  Future<void> loadData({bool hanyaAktif = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getAll(hanyaAktif: hanyaAktif);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tambah(PembayaranTarifModel tarif) async {
    await _service.create(tarif);
    await loadData();
    _pastikanBerhasilMuat();
  }

  Future<void> ubah(String id, PembayaranTarifModel tarif) async {
    await _service.update(id, tarif);
    await loadData();
    _pastikanBerhasilMuat();
  }

  Future<void> ubahStatus({required String id, required bool aktif}) async {
    await _service.setAktif(id: id, aktif: aktif);

    await loadData();
    _pastikanBerhasilMuat();
  }

  void _pastikanBerhasilMuat() {
    if (_errorMessage != null) {
      throw Exception(
        'Perubahan tersimpan, tetapi daftar tarif gagal dimuat ulang: $_errorMessage',
      );
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
