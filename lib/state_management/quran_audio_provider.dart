import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  int? _playingSurah;
  bool _isLoading = false;
  String? _errorMessage;

  int? get playingSurah => _playingSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isPlayingSurah(int nomorSurah) {
    return _playingSurah == nomorSurah && _player.playing;
  }

  Future<void> toggleAudio({
    required int nomorSurah,
    required String audioUrl,
  }) async {
    if (audioUrl.isEmpty) {
      _errorMessage = 'Audio surah tidak tersedia.';
      notifyListeners();
      return;
    }

    // Jika surah yang sama sedang diputar
    if (_playingSurah == nomorSurah) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }

      notifyListeners();
      return;
    }

    await _playNewAudio(nomorSurah: nomorSurah, audioUrl: audioUrl);
  }

  Future<void> _playNewAudio({
    required int nomorSurah,
    required String audioUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _playingSurah = nomorSurah;

      notifyListeners();

      await _player.stop();

      await _player.setUrl(audioUrl);

      _isLoading = false;
      notifyListeners();

      await _player.play();

      // Audio selesai
      if (_playingSurah == nomorSurah) {
        _playingSurah = null;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _playingSurah = null;
      _errorMessage = 'Gagal memutar audio surah.';

      notifyListeners();

      debugPrint('QURAN AUDIO ERROR: $e');
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();

    _playingSurah = null;
    _isLoading = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
