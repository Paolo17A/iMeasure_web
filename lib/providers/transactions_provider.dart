import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class TransactionsNotifier extends ChangeNotifier {
  List<DocumentSnapshot> transactionDocs = [];
  bool isChronological = false;

  void setTransactionDocs(List<DocumentSnapshot> transactions) {
    transactionDocs = transactions;
    isChronological ? sortFromEarliestToLatest() : sortFromLatestToEarliest();
    notifyListeners();
  }

  setIsChronological(bool value) {
    isChronological = value;
    isChronological ? sortFromEarliestToLatest() : sortFromLatestToEarliest();
    notifyListeners();
  }

  sortFromLatestToEarliest() {
    transactionDocs.sort((a, b) {
      DateTime aTime = (a[TransactionFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[TransactionFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
  }

  sortFromEarliestToLatest() {
    transactionDocs.sort((a, b) {
      DateTime aTime = (a[TransactionFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[TransactionFields.dateCreated] as Timestamp).toDate();
      return aTime.compareTo(bTime);
    });
  }
}

final transactionsProvider = ChangeNotifierProvider<TransactionsNotifier>(
    (ref) => TransactionsNotifier());
