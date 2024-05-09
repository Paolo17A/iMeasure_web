import 'package:flutter/material.dart';

class WindowFieldModel {
  TextEditingController nameController = TextEditingController();
  bool isMandatory = true;
  String priceBasis = 'WIDTH';
  TextEditingController brownPriceController = TextEditingController();
  TextEditingController whitePriceController = TextEditingController();
  TextEditingController mattBlackPriceController = TextEditingController();
  TextEditingController mattGrayPriceController = TextEditingController();
  TextEditingController woodFinishPriceController = TextEditingController();

  WindowFieldModel();

  static bool hasInvalidField(List<WindowFieldModel> windowFieldModels) {
    for (var windowFieldModel in windowFieldModels) {
      if (windowFieldModel.nameController.text.isEmpty ||
          windowFieldModel.brownPriceController.text.isEmpty ||
          windowFieldModel.whitePriceController.text.isEmpty ||
          windowFieldModel.mattBlackPriceController.text.isEmpty ||
          windowFieldModel.mattGrayPriceController.text.isEmpty ||
          windowFieldModel.woodFinishPriceController.text.isEmpty) {
        return true;
      }

      if (double.tryParse(windowFieldModel.brownPriceController.text) == null ||
          double.parse(windowFieldModel.brownPriceController.text) <= 0) {
        return true;
      }
      if (double.tryParse(windowFieldModel.whitePriceController.text) == null ||
          double.parse(windowFieldModel.whitePriceController.text) <= 0) {
        return true;
      }
      if (double.tryParse(windowFieldModel.mattBlackPriceController.text) ==
              null ||
          double.parse(windowFieldModel.mattBlackPriceController.text) <= 0) {
        return true;
      }
      if (double.tryParse(windowFieldModel.mattGrayPriceController.text) ==
              null ||
          double.parse(windowFieldModel.mattGrayPriceController.text) <= 0) {
        return true;
      }
      if (double.tryParse(windowFieldModel.woodFinishPriceController.text) ==
              null ||
          double.parse(windowFieldModel.woodFinishPriceController.text) <= 0) {
        return true;
      }
    }
    return false;
  }
}

class WindowAccessoryModel {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  WindowAccessoryModel();

  static bool hasInvalidField(
      List<WindowAccessoryModel> windowAccessoryModels) {
    for (var windowAccessoryModel in windowAccessoryModels) {
      if (windowAccessoryModel.nameController.text.isEmpty ||
          windowAccessoryModel.priceController.text.isEmpty) {
        return true;
      }

      if (double.tryParse(windowAccessoryModel.priceController.text) == null ||
          double.parse(windowAccessoryModel.priceController.text) <= 0) {
        return true;
      }
    }
    return false;
  }
}
