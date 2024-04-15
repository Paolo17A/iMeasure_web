import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WindowsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> windowDocs = [];

  void setWindowDocs(List<DocumentSnapshot> windows) {
    windowDocs = windows;
    notifyListeners();
  }
}

final windowsProvider =
    ChangeNotifierProvider<WindowsNotifier>((ref) => WindowsNotifier());
