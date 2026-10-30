import 'package:flutter/foundation.dart';
import '../models/profile/profile_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  ProfileModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  ProfileModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get isStaff => _user?.role == 'staff';
  bool get isPengajar => _user?.role == 'pengajar';
  bool get isSantri => _user?.role == 'santri';

  String? get userName => _user?.username;

  // GETTER USERPROFILE MENGAMBIL DATA LANGSUNG DARI _USER (SINGLE SOURCE OF TRUTH)
  Map<String, dynamic>? get userProfile {
    if (_user == null) return null;

    return {
      'id': _user!.id,
      'username': _user!.username,
      'alamat': _user!.alamat,
      'nohp': _user!.noHp,
      'role': _user!.role,
      'avatar_url': _user!.avatarUrl, // Mengambil avatarUrl dari UserModel
      'created_at': _user!.createdAt?.toIso8601String(),
    };
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _authService.currentSession;

      if (session == null) {
        _user = null;
        return;
      }

      final profile = await _authService.getUserProfile();

      if (profile == null) {
        await _authService.logout();
        _user = null;
        return;
      }

      _user = profile;
    } catch (e) {
      _errorMessage = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      final profile = await _authService.getUserProfile();

      if (profile == null) {
        _errorMessage = 'Data profile pengguna tidak ditemukan.';
        await _authService.logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Email atau password Anda salah.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // METHOD MEMPERBARUI AVATAR DI STATE LOKAL & TRIGGER REBUILD UI
  void updateAvatarUrl(String newUrl) {
    if (_user != null) {
      _user = ProfileModel(
        id: _user!.id,
        username: _user!.username,
        alamat: _user!.alamat,
        noHp: _user!.noHp,
        role: _user!.role,
        avatarUrl: newUrl, // Nilai avatarUrl baru dimasukkan ke ProfileModel
        createdAt: _user!.createdAt,
      );
      notifyListeners(); // Memicu UI ProfileInfoPage untuk merender ulang
    }
  }
}
