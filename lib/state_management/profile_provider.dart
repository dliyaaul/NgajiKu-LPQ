import 'package:flutter/foundation.dart';
import 'package:ptl_mobile/state_management/loading_provider.dart';

import '../models/profile/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  // ============================================================
  // STATE
  // ============================================================

  List<ProfileModel> _items = [];

  List<ProfileModel> _santri = [];

  List<ProfileModel> _pengajar = [];

  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // GETTER
  // ============================================================

  List<ProfileModel> get items => _items;

  List<ProfileModel> get santri => _santri;

  List<ProfileModel> get pengajar => _pengajar;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  bool get hasData => _items.isNotEmpty;

  bool get hasSantri => _santri.isNotEmpty;

  bool get hasPengajar => _pengajar.isNotEmpty;

  // ============================================================
  // GET ALL
  // ============================================================

  Future<void> loadAll(LoadingProvider loadingProvider) async {
    _clearError();

    await loadingProvider.runWithLoading(() async {
      try {
        _items = await _service.getAllProfiles();

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data profile...");
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<ProfileModel?> getById(
    String id, {
    required LoadingProvider loadingProvider,
  }) async {
    return await loadingProvider.runWithLoading(() async {
      try {
        return await _service.getProfileById(id);
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();

        return null;
      }
    }, message: "Mengambil profile...");
  }

  // ============================================================
  // GET BY ROLE
  // ============================================================

  Future<void> loadByRole(String role, LoadingProvider loadingProvider) async {
    await loadingProvider.runWithLoading(() async {
      try {
        final data = await _service.getProfilesByRole(role);

        if (role.toLowerCase() == 'santri') {
          _santri = data;
        } else if (role.toLowerCase() == 'pengajar') {
          _pengajar = data;
        } else {
          _items = data;
        }

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data $role...");
  }

  // ============================================================
  // LOAD SANTRI
  // ============================================================

  Future<void> loadSantri(LoadingProvider loadingProvider) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _santri = await _service.getProfilesByRole('santri');

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data santri...");
  }

  // ============================================================
  // LOAD PENGAJAR
  // ============================================================

  Future<void> loadPengajar(LoadingProvider loadingProvider) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _pengajar = await _service.getProfilesByRole('pengajar');

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat data pengajar...");
  }

  // ============================================================
  // LOAD STAFF
  // ============================================================

  Future<void> loadStaff(LoadingProvider loadingProvider) async {
    await loadByRole('staff', loadingProvider);
  }

  // ============================================================
  // LOAD ADMIN
  // ============================================================

  Future<void> loadAdmin(LoadingProvider loadingProvider) async {
    await loadByRole('admin', loadingProvider);
  }

  // ============================================================
  // LOAD SANTRI BY LEMBAGA
  // ============================================================

  Future<void> loadSantriByLembaga(
    String lembagaId,
    LoadingProvider loadingProvider,
  ) async {
    await loadingProvider.runWithLoading(() async {
      try {
        _santri = await _service.getSantriByLembaga(lembagaId);

        notifyListeners();
      } catch (e) {
        _errorMessage = _cleanError(e);

        notifyListeners();
      }
    }, message: "Memuat santri lembaga...");
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(
    ProfileModel profile, {
    required LoadingProvider loadingProvider,
  }) async {
    _clearError();
    _setSaving(true);

    try {
      return await loadingProvider.runWithLoading(() async {
        try {
          final updated = await _service.updateProfile(profile);

          final itemIndex = _items.indexWhere((item) => item.id == profile.id);

          if (itemIndex != -1) {
            _items[itemIndex] = updated;
          }

          final santriIndex = _santri.indexWhere(
            (item) => item.id == profile.id,
          );

          if (santriIndex != -1) {
            _santri[santriIndex] = updated;
          }

          final pengajarIndex = _pengajar.indexWhere(
            (item) => item.id == profile.id,
          );

          if (pengajarIndex != -1) {
            _pengajar[pengajarIndex] = updated;
          }

          notifyListeners();

          return true;
        } catch (e) {
          _errorMessage = _cleanError(e);

          notifyListeners();

          return false;
        }
      }, message: "Memperbarui profile...");
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
      final result = await loadingProvider.runWithLoading(() async {
        try {
          await _service.deleteProfile(id);

          _items.removeWhere((item) => item.id == id);

          _santri.removeWhere((item) => item.id == id);

          _pengajar.removeWhere((item) => item.id == id);

          notifyListeners();

          return true;
        } catch (e) {
          _errorMessage = _cleanError(e);

          notifyListeners();

          return false;
        }
      }, message: "Menghapus profile...");
      return result;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh(LoadingProvider loadingProvider) async {
    await loadAll(loadingProvider);
  }

  Future<void> refreshSantri(LoadingProvider loadingProvider) async {
    await loadSantri(loadingProvider);
  }

  Future<void> refreshPengajar(LoadingProvider loadingProvider) async {
    await loadPengajar(loadingProvider);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _items = [];

    _santri = [];

    _pengajar = [];

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
