import 'package:flutter/foundation.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

import '../models/santri_program/santri_program_model.dart';
import '../services/santri_program_service.dart';

class SantriProgramProvider extends ChangeNotifier {
  final SantriProgramService _service = SantriProgramService();

  // ============================================================
  // STATE
  // ============================================================

  List<SantriProgramModel> _items = [];

  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // GETTER
  // ============================================================

  List<SantriProgramModel> get items => _items;

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
        _items = await _service.getAll();

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat program santri...");
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<SantriProgramModel?> getById(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    return await loadingProvider.runWithLoading(() async {
      try {
        return await _service.getById(id);
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return null;
      }
    }, message: "Mengambil data program santri...");
  }

  // ============================================================
  // LOAD BY SANTRI
  // ============================================================

  Future<void> loadBySantri(
    String santriId,
    LoadingProvider loadingProvider,
  ) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getBySantri(santriId);

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data santri...");
  }

  // ============================================================
  // LOAD BY PENGAJAR
  // ============================================================

  Future<void> loadByPengajar(
    String pengajarId,
    LoadingProvider loadingProvider,
  ) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getByPengajar(pengajarId);

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data pengajar...");
  }

  // ============================================================
  // LOAD BY PROGRAM
  // ============================================================

  Future<void> loadByProgram(
    String programId,
    LoadingProvider loadingProvider,
  ) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getByProgram(programId);

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data program...");
  }

  // ============================================================
  // LOAD BY PROGRAM + KELAS PENGAJARAN
  // ============================================================

  Future<void> loadByProgramAndKelasPengajaran({
    required String programId,
    required String kelasPengajaranId,
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getByProgramAndKelasPengajaran(
          programId: programId,
          kelasPengajaranId: kelasPengajaranId,
        );

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data santri kelas...");
  }

  // ============================================================
  // LOAD BY KELAS
  // ============================================================

  Future<void> loadByKelasType(
    String kelasTypeId,
    LoadingProvider loadingProvider,
  ) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getByKelasType(kelasTypeId);

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data kelas...");
  }

  // ============================================================
  // LOAD BY PROGRAM + KELAS
  // ============================================================

  Future<void> loadByProgramAndKelas({
    required String programId,
    required String kelasTypeId,
    required LoadingProvider loadingProvider,
  }) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getByProgramAndKelas(
          programId: programId,
          kelasTypeId: kelasTypeId,
        );

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat program dan kelas...");
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<bool> create(
    SantriProgramModel data, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final created = await _service.create(data);

        _items.insert(0, created);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menambahkan program santri...");

    _setSaving(false);

    return result;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(
    SantriProgramModel data, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final updated = await _service.update(data);

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
    }, message: "Memperbarui program santri...");

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
        await _service.delete(id);

        _items.removeWhere((item) => item.id == id);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menghapus program santri...");

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
    return error.toString().replaceFirst('Exception: ', '');
  }
}
