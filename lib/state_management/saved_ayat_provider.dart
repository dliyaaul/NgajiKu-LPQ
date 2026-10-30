import 'package:flutter/material.dart';

class SavedAyatItem {
  final int nomorSurah;
  final String namaSurah;
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;

  SavedAyatItem({
    required this.nomorSurah,
    required this.namaSurah,
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
  });

  // Unique Key untuk mengidentifikasi ayat
  String get id => '$nomorSurah:$nomorAyat';
}

class SavedAyatProvider extends ChangeNotifier {
  final List<SavedAyatItem> _savedAyatList = [];

  List<SavedAyatItem> get savedAyatList => List.unmodifiable(_savedAyatList);

  bool isSaved(int nomorSurah, int nomorAyat) {
    return _savedAyatList.any(
      (item) => item.nomorSurah == nomorSurah && item.nomorAyat == nomorAyat,
    );
  }

  void toggleSaveAyat(SavedAyatItem item) {
    final index = _savedAyatList.indexWhere(
      (e) => e.nomorSurah == item.nomorSurah && e.nomorAyat == item.nomorAyat,
    );

    if (index >= 0) {
      _savedAyatList.removeAt(index);
    } else {
      _savedAyatList.add(item);
    }
    notifyListeners();
  }

  void removeAyat(int nomorSurah, int nomorAyat) {
    _savedAyatList.removeWhere(
      (e) => e.nomorSurah == nomorSurah && e.nomorAyat == nomorAyat,
    );
    notifyListeners();
  }
}
