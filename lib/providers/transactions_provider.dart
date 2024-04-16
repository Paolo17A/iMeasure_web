import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> transactionDocs = [];

  void setTransactionDocs(List<DocumentSnapshot> transactions) {
    transactionDocs = transactions;
    notifyListeners();
  }
}

final transactionsProvider = ChangeNotifierProvider<TransactionsNotifier>(
    (ref) => TransactionsNotifier());
