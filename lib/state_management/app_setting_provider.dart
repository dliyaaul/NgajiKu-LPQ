import 'package:flutter/material.dart';

import '../models/app_settings/app_setting_model.dart';
import '../services/app_setting_service.dart';

class AppSettingProvider extends ChangeNotifier {
  final AppSettingService _service = AppSettingService();

  Map<String, AppSettingModel> _settings = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  Map<String, AppSettingModel> get settings => _settings;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // TAHUN AJARAN
  // ============================================================

  String get tahunAjaran {
    return _settings['tahun_ajaran']?.settingValue ?? '-';
  }

  // ============================================================
  // LOAD SETTINGS
  // ============================================================

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getAllSettings();

      _settings = {for (final item in data) item.settingKey: item};
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE SETTING
  // ============================================================

  Future<bool> updateSetting({
    required String key,
    required String value,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateSetting(key: key, value: value);

      final oldSetting = _settings[key];

      if (oldSetting != null) {
        _settings[key] = AppSettingModel(
          id: oldSetting.id,
          settingKey: oldSetting.settingKey,
          settingValue: value,
          description: oldSetting.description,
          updatedAt: DateTime.now(),
          updatedBy: oldSetting.updatedBy,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE TAHUN AJARAN
  // ============================================================

  Future<bool> updateTahunAjaran(String value) async {
    return updateSetting(key: 'tahun_ajaran', value: value);
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
