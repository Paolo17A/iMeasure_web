import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class CartNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _cartItems = [];
  List<DocumentSnapshot> _itemDocs = [];
  String _selectedPaymentMethod = '';
  String _selectedCartItem = '';
  String _selectedGlassType = '';
  String _selectedColor = '';

  List<DocumentSnapshot> get cartItems => _cartItems;
  List<DocumentSnapshot> get itemDocs => _itemDocs;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get selectedCartItem => _selectedCartItem;
  String get selectedGlassType => _selectedGlassType;
  String get selectedColor => _selectedColor;

  void setCartItems(List<DocumentSnapshot> items) {
    _cartItems = items;
    notifyListeners();
  }

  void setItemDocs(List<DocumentSnapshot> items) {
    _itemDocs = items;
    notifyListeners();
  }

  void addCartItem(dynamic item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeCartItem(DocumentSnapshot item) {
    _cartItems.remove(item);
    if (item.id == _selectedCartItem) {
      setSelectedCartItem('');
    }
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

  void setSelectedCartItem(String cartID) {
    _selectedCartItem = cartID;
    notifyListeners();
  }

  void setGlassType(String glass) {
    _selectedGlassType = glass;
    notifyListeners();
  }

  DocumentSnapshot? getSelectedCartDoc() {
    return _cartItems
        .where((element) => element.id == _selectedCartItem)
        .firstOrNull;
  }
}

final cartProvider =
    ChangeNotifierProvider<CartNotifier>((ref) => CartNotifier());
