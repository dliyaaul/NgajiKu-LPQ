import 'package:flutter/foundation.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

import '../models/kelas/kelas_type_model.dart';
import '../services/kelas_type_service.dart';

class KelasTypeProvider extends ChangeNotifier {
  final KelasTypeService _service = KelasTypeService();

  // ============================================================
  // STATE
  // ============================================================

  List<KelasTypeModel> _items = [];

  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // GETTER
  // ============================================================

  List<KelasTypeModel> get items => _items;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get hasData => _items.isNotEmpty;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadAll(LoadingProvider loadingProvider) async {
    _clearError();

    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getAllKelasTypes();

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat jenis kelas...");
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<KelasTypeModel?> getById(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    return await loadingProvider.runWithLoading(() async {
      try {
        return await _service.getKelasTypeById(id);
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return null;
      }
    }, message: "Mengambil jenis kelas...");
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create({
    required String nama,
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final created = await _service.createKelasType(nama: nama);

        _items.insert(0, created);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menambahkan jenis kelas...");

    _setSaving(false);

    return result;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(
    KelasTypeModel data, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final updated = await _service.updateKelasType(
          id: data.id,
          nama: data.nama,
        );

        final index = _items.indexWhere((item) => item.id == data.id);

        if (index != -1) {
          _items[index] = updated;
        }

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Memperbarui jenis kelas...");

    _setSaving(false);

    return result;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> delete(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        await _service.deleteKelasType(id);

        _items.removeWhere((item) => item.id == id);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menghapus jenis kelas...");

    _setSaving(false);

    return result;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh(LoadingProvider loadingProvider) async {
    await loadAll(loadingProvider);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _items = [];

    _errorMessage = null;

    notifyListeners();
  }

  void clearError() {
    _clearError();

    notifyListeners();
  }

  // ============================================================
  // PRIVATE
  // ============================================================

  void _setSaving(bool value) {
    _isSaving = value;

    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}
