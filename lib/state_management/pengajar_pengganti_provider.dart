import 'package:flutter/foundation.dart';

import '../models/pengajar_pengganti/pengajar_pengganti_model.dart';
import '../services/pengajar_pengganti_service.dart';
import 'loading_provider.dart';

class PengajarPenggantiProvider extends ChangeNotifier {
  final PengajarPenggantiService _service = PengajarPenggantiService();

  // ============================================================
  // STATE
  // ============================================================

  List<PengajarPenggantiModel> _items = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  List<PengajarPenggantiModel> get items => List.unmodifiable(_items);

  List<PengajarPenggantiModel> get itemsAktif =>
      List.unmodifiable(_items.where((item) => item.aktif).toList());

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get hasData => _items.isNotEmpty;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadAll({
    bool hanyaAktif = false,
    LoadingProvider? loadingProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Future<void> load() async {
        final data = await _service.getAll(hanyaAktif: hanyaAktif);

        debugPrint('=== PENGAJAR PENGGANTI PROVIDER ===');
        debugPrint('data: $data');
        debugPrint('jumlah data: ${data.length}');

        _items = data;

        debugPrint('items: $_items');
        debugPrint('itemsAktif: $itemsAktif');
      }

      if (loadingProvider != null) {
        await loadingProvider.runWithLoading(
          load,
          message: 'Memuat pengajar pengganti...',
        );
      } else {
        await load();
      }
    } catch (e) {
      _errorMessage = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<PengajarPenggantiModel?> getById(String id) async {
    try {
      _errorMessage = null;

      return await _service.getById(id);
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create({
    required String nama,
    String? noHp,
    bool aktif = true,
    LoadingProvider? loadingProvider,
  }) async {
    if (nama.trim().isEmpty) {
      _errorMessage = 'Nama pengajar pengganti wajib diisi.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Future<void> save() async {
        final model = PengajarPenggantiModel(
          id: '',
          nama: nama.trim(),
          noHp: _normalizeNullable(noHp),
          aktif: aktif,
          createdBy: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await _service.create(model);

        _items.add(created);

        _sortItems();
      }

      if (loadingProvider != null) {
        await loadingProvider.runWithLoading(
          save,
          message: 'Menyimpan pengajar pengganti...',
        );
      } else {
        await save();
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update({
    required String id,
    required String nama,
    String? noHp,
    required bool aktif,
    LoadingProvider? loadingProvider,
  }) async {
    if (nama.trim().isEmpty) {
      _errorMessage = 'Nama pengajar pengganti wajib diisi.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Future<void> save() async {
        final index = _items.indexWhere((item) => item.id == id);

        final existing = index != -1
            ? _items[index]
            : await _service.getById(id);

        if (existing == null) {
          throw Exception('Data pengajar pengganti tidak ditemukan.');
        }

        final model = existing.copyWith(
          nama: nama.trim(),
          noHp: _normalizeNullable(noHp),
          aktif: aktif,
        );

        final updated = await _service.update(model);

        if (index != -1) {
          _items[index] = updated;
        } else {
          _items.add(updated);
        }

        _sortItems();
      }

      if (loadingProvider != null) {
        await loadingProvider.runWithLoading(
          save,
          message: 'Memperbarui pengajar pengganti...',
        );
      } else {
        await save();
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> delete(String id, {LoadingProvider? loadingProvider}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Future<void> remove() async {
        await _service.delete(id);

        _items.removeWhere((item) => item.id == id);
      }

      if (loadingProvider != null) {
        await loadingProvider.runWithLoading(
          remove,
          message: 'Menghapus pengajar pengganti...',
        );
      } else {
        await remove();
      }

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SET AKTIF
  // ============================================================

  Future<bool> setAktif({
    required String id,
    required bool aktif,
    LoadingProvider? loadingProvider,
  }) async {
    _errorMessage = null;

    try {
      Future<void> updateStatus() async {
        final updated = await _service.setAktif(id, aktif);

        final index = _items.indexWhere((item) => item.id == id);

        if (index != -1) {
          _items[index] = updated;
        } else {
          _items.add(updated);
          _sortItems();
        }
      }

      if (loadingProvider != null) {
        await loadingProvider.runWithLoading(
          updateStatus,
          message: aktif
              ? 'Mengaktifkan pengajar pengganti...'
              : 'Menonaktifkan pengajar pengganti...',
        );
      } else {
        await updateStatus();
      }

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<PengajarPenggantiModel>> search(
    String keyword, {
    bool hanyaAktif = false,
  }) async {
    try {
      _errorMessage = null;

      return await _service.search(keyword, hanyaAktif: hanyaAktif);
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();

      return [];
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData() {
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh({
    bool hanyaAktif = false,
    LoadingProvider? loadingProvider,
  }) async {
    await loadAll(hanyaAktif: hanyaAktif, loadingProvider: loadingProvider);
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  String? _normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  void _sortItems() {
    _items.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
