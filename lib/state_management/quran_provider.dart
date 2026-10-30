import 'package:flutter/foundation.dart';

import '../models/quran/ayat_model.dart';
import '../models/quran/surah_model.dart';
import '../services/quran_service.dart';

class QuranProvider extends ChangeNotifier {
  final QuranService _quranService = QuranService();

  // ============================================================
  // SURAH
  // ============================================================

  List<SurahModel> _surahList = [];

  bool _isLoadingSurah = false;

  // ============================================================
  // AYAT
  // ============================================================

  List<AyatModel> _ayatList = [];

  bool _isLoadingAyat = false;

  int? _selectedSurah;

  // ============================================================
  // ERROR
  // ============================================================

  String? _errorMessage;

  // ============================================================
  // GETTER
  // ============================================================

  List<SurahModel> get surahList => _surahList;

  List<AyatModel> get ayatList => _ayatList;

  bool get isLoadingSurah => _isLoadingSurah;

  bool get isLoadingAyat => _isLoadingAyat;

  bool get hasSurahData => _surahList.isNotEmpty;

  bool get hasAyatData => _ayatList.isNotEmpty;

  String? get errorMessage => _errorMessage;

  int? get selectedSurah => _selectedSurah;

  // ============================================================
  // GET DAFTAR SURAH
  // ============================================================

  Future<void> fetchSurahList({bool forceRefresh = false}) async {
    if (_surahList.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoadingSurah = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _surahList = await _quranService.getSurahList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingSurah = false;

      notifyListeners();
    }
  }

  // ============================================================
  // GET AYAT
  // ============================================================

  Future<void> fetchAyat(int nomorSurah) async {
    _isLoadingAyat = true;
    _errorMessage = null;
    _ayatList = [];
    _selectedSurah = nomorSurah;

    notifyListeners();

    try {
      _ayatList = await _quranService.getAyatBySurah(nomorSurah);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingAyat = false;

      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshSurahList() async {
    await fetchSurahList(forceRefresh: true);
  }

  Future<void> refreshAyat() async {
    if (_selectedSurah == null) return;

    await fetchAyat(_selectedSurah!);
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
