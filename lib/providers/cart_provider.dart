import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class CartNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _cartItems = [];
  //List<DocumentSnapshot> _itemDocs = [];
  String _selectedPaymentMethod = '';
  List<String> _selectedCartItemIDs = [];
  String _selectedGlassType = '';
  String _selectedColor = '';

  List<DocumentSnapshot> get cartItems => _cartItems;
  //List<DocumentSnapshot> get itemDocs => _itemDocs;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  List<String> get selectedCartItemIDs => _selectedCartItemIDs;
  String get selectedGlassType => _selectedGlassType;
  String get selectedColor => _selectedColor;

  void setCartItems(List<DocumentSnapshot> items) {
    _cartItems = items;
    notifyListeners();
  }

  /*void setItemDocs(List<DocumentSnapshot> items) {
    _itemDocs = items;
    notifyListeners();
  }*/

  void addCartItem(dynamic item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeCartItem(DocumentSnapshot item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  bool cartContainsThisItem(String itemID) {
    return _cartItems.any((cartItem) {
      final cartData = cartItem.data() as Map<dynamic, dynamic>;
      return cartData[CartFields.itemID] == itemID;
    });
  }

  void setSelectedPaymentMethod(String paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  void setSelectedColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void selectCartItem(String item) {
    if (selectedCartItemIDs.contains(item)) return;
    _selectedCartItemIDs.add(item);
    notifyListeners();
  }

  void deselectCartItem(String item) {
    if (!selectedCartItemIDs.contains(item)) return;
    _selectedCartItemIDs.remove(item);
    notifyListeners();
  }

  void resetSelectedCartItems() {
    _selectedCartItemIDs.clear();
    notifyListeners();
  }

  void setGlassType(String glass) {
    _selectedGlassType = glass;
    notifyListeners();
  }
}

final cartProvider =
    ChangeNotifierProvider<CartNotifier>((ref) => CartNotifier());
