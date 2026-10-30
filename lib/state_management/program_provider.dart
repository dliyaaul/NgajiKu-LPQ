import 'package:flutter/foundation.dart';

import '../models/program/program_model.dart';
import '../services/program_service.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

class ProgramProvider extends ChangeNotifier {
  final ProgramService _service = ProgramService();

  List<ProgramModel> _items = [];

  bool _isSaving = false;

  String? _errorMessage;

  List<ProgramModel> get items => _items;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get hasData => _items.isNotEmpty;

  // ===============================
  // GET ALL PROGRAM
  // ===============================

  Future<void> loadAll(LoadingProvider loadingProvider) async {
    _clearError();

    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getAllPrograms();

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat program...");
  }

  // ===============================
  // GET PROGRAM BY ID
  // ===============================

  Future<ProgramModel?> getById(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    return await loadingProvider.runWithLoading(() async {
      try {
        return await _service.getProgramById(id);
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return null;
      }
    }, message: "Mengambil detail program...");
  }
  // ===============================
  // CREATE
  // ===============================

  Future<bool> create({
    required String nama,
    String? deskripsi,
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final created = await _service.createProgram(
          nama: nama,
          deskripsi: deskripsi,
        );

        _items.insert(0, created);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menyimpan program...");

    _setSaving(false);

    return result;
  }

  // ===============================
  // UPDATE
  // ===============================

  Future<bool> update(
    ProgramModel data, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        final updated = await _service.updateProgram(data);

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
    }, message: "Memperbarui program...");

    _setSaving(false);

    return result;
  }

  // ===============================
  // DELETE
  // ===============================

  Future<bool> delete(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();

    _setSaving(true);

    final result = await loadingProvider.runWithLoading(() async {
      try {
        await _service.deleteProgram(id);

        _items.removeWhere((item) => item.id == id);

        notifyListeners();

        return true;
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return false;
      }
    }, message: "Menghapus program...");

    _setSaving(false);

    return result;
  }

  Future<void> refresh(LoadingProvider loadingProvider) async {
    await loadAll(loadingProvider);
  }

  void clear() {
    _items = [];

    _errorMessage = null;

    notifyListeners();
  }

  void clearError() {
    _clearError();

    notifyListeners();
  }

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
