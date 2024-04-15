import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadedImageNotifier extends ChangeNotifier {
  Uint8List? uploadedImage = null;

  void removeImage() {
    uploadedImage = null;
    notifyListeners();
  }

  void addImage(Uint8List image) {
    uploadedImage = image;
    notifyListeners();
  }
}

final uploadedImageProvider =
    ChangeNotifierProvider<UploadedImageNotifier>((ref) {
  return UploadedImageNotifier();
});
