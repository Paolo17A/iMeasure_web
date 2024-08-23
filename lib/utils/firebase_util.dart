//==============================================================================
//USERS=========================================================================
//==============================================================================
// ignore_for_file: unnecessary_cast

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/providers/windows_provider.dart';

import '../models/window_models.dart';
import '../providers/loading_provider.dart';
import 'go_router_util.dart';
import 'string_util.dart';

bool hasLoggedInUser() {
  return FirebaseAuth.instance.currentUser != null;
}

Future logInUser(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);
    final userDoc = await getCurrentUserDoc();
    final userData = userDoc.data() as Map<dynamic, dynamic>;

    if (userData[UserFields.userType] != UserTypes.admin) {
      await FirebaseAuth.instance.signOut();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Only admins may log-in to the web platform.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }

    //  reset the password in firebase in case client reset it using an email link.
    if (userData[UserFields.password] != passwordController.text) {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({UserFields.password: passwordController.text});
    }
    ref.read(loadingProvider.notifier).toggleLoading(false);
    GoRouter.of(context).goNamed(GoRoutes.home);
    GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error logging in: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future<String> getCurrentUserType() async {
  final userDoc = await getCurrentUserDoc();
  final userData = userDoc.data() as Map<dynamic, dynamic>;
  return userData[UserFields.userType];
}

Future<DocumentSnapshot> getCurrentUserDoc() async {
  return await getThisUserDoc(FirebaseAuth.instance.currentUser!.uid);
}

Future<DocumentSnapshot> getThisUserDoc(String userID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(userID)
      .get();
}

Future<List<DocumentSnapshot>> getAllClientDocs() async {
  final users = await FirebaseFirestore.instance
      .collection(Collections.users)
      .where(UserFields.userType, isEqualTo: UserTypes.client)
      .get();
  return users.docs;
}

//==============================================================================
//WINDOWS=======================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllWindowDocs() async {
  final windows =
      await FirebaseFirestore.instance.collection(Collections.windows).get();
  return windows.docs.map((window) => window as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisWindowDoc(String windowID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.windows)
      .doc(windowID)
      .get();
}

Future addWindowEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController minHeightController,
    required TextEditingController maxHeightController,
    required TextEditingController minWidthController,
    required TextEditingController maxWidthController,
    required List<WindowFieldModel> windowFieldModels,
    required List<WindowAccessoryModel> windowAccesoryModels}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      minHeightController.text.isEmpty ||
      maxHeightController.text.isEmpty ||
      minWidthController.text.isEmpty ||
      maxWidthController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (double.tryParse(minHeightController.text) == null ||
      double.parse(minHeightController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the minimum height.')));
    return;
  }
  if (double.tryParse(maxHeightController.text) == null ||
      double.parse(maxHeightController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for maximum height.')));
    return;
  }
  if (double.tryParse(minWidthController.text) == null ||
      double.parse(minWidthController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the minimum width.')));
    return;
  }
  if (double.tryParse(maxWidthController.text) == null ||
      double.parse(maxWidthController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for maximum width.')));
    return;
  }
  if (ref.read(uploadedImageProvider).uploadedImage == null) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please upload a window image.')));
    return;
  }
  if (WindowFieldModel.hasInvalidField(windowFieldModels)) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Please fill up all window field parameters with valid input.')));
    return;
  }

  if (WindowAccessoryModel.hasInvalidField(windowAccesoryModels)) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Please fill up all window accessory parameters with valid input.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    List<Map<dynamic, dynamic>> windowFields = [];
    for (var windowFieldModel in windowFieldModels) {
      Map<dynamic, dynamic> windowField = {
        WindowSubfields.name: windowFieldModel.nameController.text.trim(),
        WindowSubfields.isMandatory: windowFieldModel.isMandatory,
        WindowSubfields.priceBasis: windowFieldModel.priceBasis,
        WindowSubfields.brownPrice:
            double.parse(windowFieldModel.brownPriceController.text.trim()),
        WindowSubfields.mattBlackPrice:
            double.parse(windowFieldModel.mattBlackPriceController.text.trim()),
        WindowSubfields.mattGrayPrice:
            double.parse(windowFieldModel.mattGrayPriceController.text.trim()),
        WindowSubfields.woodFinishPrice: double.parse(
            windowFieldModel.woodFinishPriceController.text.trim()),
        WindowSubfields.whitePrice:
            double.parse(windowFieldModel.whitePriceController.text.trim())
      };
      windowFields.add(windowField);
    }

    List<Map<dynamic, dynamic>> accessoryFields = [];
    for (var windowAccessoryModel in windowAccesoryModels) {
      Map<dynamic, dynamic> accessoryField = {
        WindowAccessorySubfields.name:
            windowAccessoryModel.nameController.text.trim(),
        WindowAccessorySubfields.price:
            double.parse(windowAccessoryModel.priceController.text.trim())
      };
      accessoryFields.add(accessoryField);
    }

    final windowReference =
        await FirebaseFirestore.instance.collection(Collections.windows).add({
      WindowFields.name: nameController.text.trim(),
      WindowFields.description: descriptionController.text.trim(),
      WindowFields.minWidth: double.parse(minWidthController.text),
      WindowFields.maxWidth: double.parse(maxWidthController.text),
      WindowFields.minHeight: double.parse(minHeightController.text),
      WindowFields.maxHeight: double.parse(maxHeightController.text),
      WindowFields.isAvailable: true,
      WindowFields.windowFields: windowFields,
      WindowFields.accessoryFields: accessoryFields
    });

    //  Upload Item Images to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.windows)
        .child('${windowReference.id}.png');
    final uploadTask =
        storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.windows)
        .doc(windowReference.id)
        .update({WindowFields.imageURL: downloadURL});
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new window.')));
    goRouter.goNamed(GoRoutes.windows);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding new window: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editWindowEntry(BuildContext context, WidgetRef ref,
    {required String windowID,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController minHeightController,
    required TextEditingController maxHeightController,
    required TextEditingController minWidthController,
    required TextEditingController maxWidthController,
    required List<WindowFieldModel> windowFieldModels,
    required List<WindowAccessoryModel> windowAccesoryModels}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      minHeightController.text.isEmpty ||
      maxHeightController.text.isEmpty ||
      minWidthController.text.isEmpty ||
      maxWidthController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  if (double.tryParse(minHeightController.text) == null ||
      double.parse(maxHeightController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the minimum height.')));
    return;
  }
  if (double.tryParse(maxHeightController.text) == null ||
      double.parse(maxHeightController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for maximum height.')));
    return;
  }
  if (double.tryParse(minWidthController.text) == null ||
      double.parse(minWidthController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid whole number greater than zero for the minimum width.')));
    return;
  }
  if (double.tryParse(maxWidthController.text) == null ||
      double.parse(maxWidthController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Please input a valid number greater than zero for maximum width.')));
    return;
  }
  if (WindowFieldModel.hasInvalidField(windowFieldModels)) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Please fill up all window field parameters with valid input.')));
  }

  if (WindowAccessoryModel.hasInvalidField(windowAccesoryModels)) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Please fill up all window accessory parameters with valid input.')));
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    List<Map<dynamic, dynamic>> windowFields = [];
    for (var windowFieldModel in windowFieldModels) {
      Map<dynamic, dynamic> windowField = {
        WindowSubfields.name: windowFieldModel.nameController.text.trim(),
        WindowSubfields.isMandatory: windowFieldModel.isMandatory,
        WindowSubfields.priceBasis: windowFieldModel.priceBasis,
        WindowSubfields.brownPrice:
            double.parse(windowFieldModel.brownPriceController.text.trim()),
        WindowSubfields.mattBlackPrice:
            double.parse(windowFieldModel.mattBlackPriceController.text.trim()),
        WindowSubfields.mattGrayPrice:
            double.parse(windowFieldModel.mattGrayPriceController.text.trim()),
        WindowSubfields.woodFinishPrice: double.parse(
            windowFieldModel.woodFinishPriceController.text.trim()),
        WindowSubfields.whitePrice:
            double.parse(windowFieldModel.whitePriceController.text.trim())
      };
      windowFields.add(windowField);
    }

    List<Map<dynamic, dynamic>> accessoryFields = [];
    for (var windowAccessoryModel in windowAccesoryModels) {
      Map<dynamic, dynamic> accessoryField = {
        WindowAccessorySubfields.name:
            windowAccessoryModel.nameController.text.trim(),
        WindowAccessorySubfields.price:
            double.parse(windowAccessoryModel.priceController.text.trim())
      };
      accessoryFields.add(accessoryField);
    }

    await FirebaseFirestore.instance
        .collection(Collections.windows)
        .doc(windowID)
        .update({
      WindowFields.name: nameController.text.trim(),
      WindowFields.description: descriptionController.text.trim(),
      WindowFields.minWidth: double.parse(minWidthController.text),
      WindowFields.maxWidth: double.parse(maxWidthController.text),
      WindowFields.minHeight: double.parse(minHeightController.text),
      WindowFields.maxHeight: double.parse(maxHeightController.text),
      WindowFields.windowFields: windowFields,
      WindowFields.accessoryFields: accessoryFields
    });

    //  Upload Item Images to Firebase Storage
    if (ref.read(uploadedImageProvider).uploadedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.windows)
          .child('${windowID}.png');
      final uploadTask =
          storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(Collections.windows)
          .doc(windowID)
          .update({WindowFields.imageURL: downloadURL});
    }

    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited window.')));
    goRouter.goNamed(GoRoutes.windows);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this window: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future toggleWindowAvailability(BuildContext context, WidgetRef ref,
    {required String windowID, required bool isAvailable}) async {
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.windows)
        .doc(windowID)
        .update({WindowFields.isAvailable: !isAvailable});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Successfully ${isAvailable ? 'archived' : 'restored'} this window')));
    ref.read(windowsProvider).setWindowDocs(await getAllWindowDocs());
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error togging window availability: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

//==============================================================================
//TRANSACTIONS-=================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllTransactionDocs() async {
  final transactions = await FirebaseFirestore.instance
      .collection(Collections.transactions)
      .get();
  return transactions.docs
      .map((transaction) => transaction as DocumentSnapshot)
      .toList();
}

Future approveThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .doc(paymentID)
        .update({
      TransactionFields.dateApproved: DateTime.now(),
      TransactionFields.paymentVerified: true,
      TransactionFields.paymentStatus: TransactionStatuses.approved
    });

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(paymentID)
        .update({OrderFields.purchaseStatus: OrderStatuses.processing});
    ref
        .read(transactionsProvider)
        .setTransactionDocs(await getAllTransactionDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully approved this payment')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error approving this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future denyThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .doc(paymentID)
        .update({
      TransactionFields.dateApproved: DateTime.now(),
      TransactionFields.paymentVerified: true,
      TransactionFields.paymentStatus: TransactionStatuses.denied
    });

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(paymentID)
        .update({OrderFields.purchaseStatus: OrderStatuses.denied});
    ref
        .read(transactionsProvider)
        .setTransactionDocs(await getAllTransactionDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully denied this payment')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denying this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//ORDERS-=======================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllOrderDocs() async {
  final orders =
      await FirebaseFirestore.instance.collection(Collections.orders).get();
  return orders.docs.reversed
      .map((order) => order as DocumentSnapshot)
      .toList();
}

Future<DocumentSnapshot> getThisOrderDoc(String orderID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.orders)
      .doc(orderID)
      .get();
}

Future<List<DocumentSnapshot>> getAllClientOrderDocs(String clientID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.clientID, isEqualTo: clientID)
      .get();
  return orders.docs.map((order) => order as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllWindowOrderDocs(String windowID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.windowID, isEqualTo: windowID)
      .get();
  return orders.docs.map((order) => order as DocumentSnapshot).toList();
}

Future markOrderAsReadyForPickUp(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.purchaseStatus: OrderStatuses.forPickUp});
    ref.read(ordersProvider).setOrderDocs(await getAllOrderDocs());
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked order as ready for pick up.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking order as ready for pick up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsPickedUp(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.purchaseStatus: OrderStatuses.pickedUp,
      OrderFields.datePickedUp: DateTime.now()
    });
    ref.read(ordersProvider).setOrderDocs(await getAllOrderDocs());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked order as picked up')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking order as picked up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future uploadQuotationPDF(BuildContext context, WidgetRef ref,
    {required String orderID,
    required Uint8List pdfBytes,
    required double laborPrice}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    //  Upload Item Images to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.orders)
        .child('$orderID.pdf');
    final uploadTask = storageRef.putData(pdfBytes);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.quotationURL: downloadURL,
      OrderFields.laborPrice: laborPrice,
      OrderFields.purchaseStatus: OrderStatuses.pending
    });
    ref.read(loadingProvider).toggleLoading(false);
    goRouter.goNamed(GoRoutes.orders);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error setting labor cost and creating quotation document: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

//==============================================================================
//==FAQS========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllFAQs() async {
  final faqs =
      await FirebaseFirestore.instance.collection(Collections.faqs).get();
  return faqs.docs;
}

Future<DocumentSnapshot> getThisFAQDoc(String faqID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.faqs)
      .doc(faqID)
      .get();
}

Future addFAQEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    String faqID = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .set({
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new FAQ.')));
    goRouter.goNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID,
    required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .update({
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this FAQ.')));
    goRouter.goNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future deleteFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .delete();
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully deleted this FAQ.')));
    goRouter.pushReplacementNamed(GoRoutes.viewFAQs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}
