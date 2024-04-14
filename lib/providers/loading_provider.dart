import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingProvider extends ChangeNotifier {
  bool isLoading = false;

  void toggleLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }
}

final loadingProvider =
    ChangeNotifierProvider<LoadingProvider>((ref) => LoadingProvider());
