import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  int _loadingCount = 0;

  String _message = 'Memuat...';

  bool get isLoading => _loadingCount > 0;

  String get message => _message;

  void show({String message = 'Memuat...'}) {
    _loadingCount++;

    _message = message;

    notifyListeners();
  }

  void hide() {
    if (_loadingCount > 0) {
      _loadingCount--;
    }

    notifyListeners();
  }

  Future<T> runWithLoading<T>(
    Future<T> Function() action, {
    String message = 'Memuat...',
  }) async {
    show(message: message);

    try {
      return await action();
    } finally {
      hide();
    }
  }

  void reset() {
    _loadingCount = 0;

    notifyListeners();
  }
}
