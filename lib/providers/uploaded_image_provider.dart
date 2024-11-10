import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadedImageNotifier extends ChangeNotifier {
  Uint8List? uploadedImage = null;
  List<Uint8List?> uploadedImages = [];

  void removeImage() {
    uploadedImage = null;
    notifyListeners();
  }

  void addImage(Uint8List image) {
    uploadedImage = image;
    notifyListeners();
  }

  void addImages(List<Uint8List?> images) {
    for (var image in images) {
      uploadedImages.add(image);
    }
    notifyListeners();
  }

  void resetImages() {
    uploadedImages.clear();
    notifyListeners();
  }

  void removeImageFromList(Uint8List image) {
    uploadedImages.remove(image);
    notifyListeners();
  }
}

final uploadedImageProvider =
    ChangeNotifierProvider<UploadedImageNotifier>((ref) {
  return UploadedImageNotifier();
});
