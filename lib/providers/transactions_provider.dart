import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class TransactionsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> transactionDocs = [];

  void setTransactionDocs(List<DocumentSnapshot> transactions) {
    transactionDocs = transactions;
    transactionDocs.sort((a, b) {
      DateTime aTime = (a[TransactionFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[TransactionFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    notifyListeners();
  }
}

final transactionsProvider = ChangeNotifierProvider<TransactionsNotifier>(
    (ref) => TransactionsNotifier());
