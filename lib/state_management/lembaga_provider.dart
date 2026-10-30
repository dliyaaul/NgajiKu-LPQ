import 'package:flutter/foundation.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

import '../models/lembaga/lembaga_model.dart';
import '../models/santri_program/santri_program_model.dart';
import '../services/lembaga_service.dart';

class LembagaProvider extends ChangeNotifier {
  final LembagaService _service = LembagaService();

  // ============================================================
  // STATE
  // ============================================================

  List<LembagaModel> _items = [];
  List<SantriProgramModel> _santriLembaga = [];

  bool _isSaving = false;
  bool _isLoadingSantri = false;

  String? _errorMessage;
  String? _santriErrorMessage;

  // Mencegah respons permintaan lama menimpa hasil permintaan terbaru.
  int _santriRequestVersion = 0;

  // ============================================================
  // GETTERS
  // ============================================================

  List<LembagaModel> get items => List.unmodifiable(_items);
  List<SantriProgramModel> get santriLembaga =>
      List.unmodifiable(_santriLembaga);

  bool get isSaving => _isSaving;
  bool get isLoadingSantri => _isLoadingSantri;
  String? get errorMessage => _errorMessage;
  String? get santriErrorMessage => _santriErrorMessage;
  bool get hasData => _items.isNotEmpty;

  // ============================================================
  // GET ALL
  // ============================================================

  Future<void> loadAll(LoadingProvider loadingProvider) async {
    _clearError();

    await loadingProvider.runWithLoading(() async {
      try {
        final data = await _service.getAllLembaga();
        _items = data;
        _errorMessage = null;
      } catch (e) {
        _errorMessage = _cleanError(e);
      }

      notifyListeners();
    }, message: 'Memuat data lembaga...');
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<LembagaModel?> getById(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final data = await _service.getLembagaById(id);
        _errorMessage = null;
        return data;
      } catch (e) {
        _errorMessage = _cleanError(e);
        return null;
      } finally {
        notifyListeners();
      }
    }, message: 'Mengambil data lembaga...');

    return result;
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create({
    required String namaLembaga,
    required String pbmType,
    String? alamat,
    String? programId,
    String? pengajarId,
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();
    _setSaving(true);

    try {
      final success = await loadingProvider.runWithLoading(() async {
        try {
          final created = await _service.createLembaga(
            namaLembaga: namaLembaga,
            pbmType: pbmType,
            alamat: alamat,
            programId: programId,
            // Legacy compatibility only; service no longer writes this field.
            pengajarId: pengajarId,
          );

          _items.removeWhere((item) => item.id == created.id);
          _items.add(created);
          _items.sort(
            (a, b) => a.namaLembaga.toLowerCase().compareTo(
              b.namaLembaga.toLowerCase(),
            ),
          );
          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (e) {
          _errorMessage = _cleanError(e);
          notifyListeners();
          return false;
        }
      }, message: 'Menambahkan lembaga...');

      return success;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(
    LembagaModel data, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();
    _setSaving(true);

    try {
      final success = await loadingProvider.runWithLoading(() async {
        try {
          final updated = await _service.updateLembaga(data);
          final index = _items.indexWhere((item) => item.id == updated.id);

          if (index == -1) {
            _items.add(updated);
          } else {
            _items[index] = updated;
          }

          _items.sort(
            (a, b) => a.namaLembaga.toLowerCase().compareTo(
              b.namaLembaga.toLowerCase(),
            ),
          );
          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (e) {
          _errorMessage = _cleanError(e);
          notifyListeners();
          return false;
        }
      }, message: 'Memperbarui lembaga...');

      return success;
    } finally {
      _setSaving(false);
    }
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

    try {
      final success = await loadingProvider.runWithLoading(() async {
        try {
          await _service.deleteLembaga(id);
          _items.removeWhere((item) => item.id == id);

          // Bersihkan detail santri jika lembaga yang sedang ditampilkan
          // kebetulan dihapus.
          _santriLembaga = _santriLembaga
              .where((item) => item.lembagaId != id)
              .toList();

          _errorMessage = null;
          notifyListeners();
          return true;
        } catch (e) {
          _errorMessage = _cleanError(e);
          notifyListeners();
          return false;
        }
      }, message: 'Menghapus lembaga...');

      return success;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // LOAD SANTRI BY LEMBAGA
  // ============================================================

  Future<void> loadSantriByLembaga(
    String lembagaId,
    LoadingProvider loadingProvider,
  ) async {
    final requestVersion = ++_santriRequestVersion;

    _isLoadingSantri = true;
    _santriErrorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getSantriByLembaga(lembagaId);

      // Abaikan respons dari permintaan yang sudah digantikan oleh refresh
      // atau perpindahan ke lembaga lain.
      if (requestVersion != _santriRequestVersion) return;

      _santriLembaga = data;
      _santriErrorMessage = null;
    } catch (e) {
      if (requestVersion != _santriRequestVersion) return;
      _santriErrorMessage = _cleanError(e);
    } finally {
      if (requestVersion == _santriRequestVersion) {
        _isLoadingSantri = false;
        notifyListeners();
      }
    }
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
    _santriLembaga = [];
    _isSaving = false;
    _isLoadingSantri = false;
    _errorMessage = null;
    _santriErrorMessage = null;
    _santriRequestVersion++;
    notifyListeners();
  }

  void clearSantriLembaga() {
    _santriLembaga = [];
    _isLoadingSantri = false;
    _santriErrorMessage = null;
    _santriRequestVersion++;
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearSantriError() {
    _santriErrorMessage = null;
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
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}
