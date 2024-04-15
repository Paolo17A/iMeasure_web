//==============================================================================
//USERS=========================================================================
//==============================================================================
// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/providers/windows_provider.dart';

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
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error logging in: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
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
    required TextEditingController maxWidthController}) async {
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
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    final windowReference =
        await FirebaseFirestore.instance.collection(Collections.windows).add({
      WindowFields.name: nameController.text.trim(),
      WindowFields.description: descriptionController.text.trim(),
      WindowFields.minWidth: double.parse(minWidthController.text),
      WindowFields.maxWidth: double.parse(maxWidthController.text),
      WindowFields.minHeight: double.parse(minHeightController.text),
      WindowFields.maxHeight: double.parse(maxHeightController.text),
      WindowFields.isAvailable: true
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
    required TextEditingController maxWidthController}) async {
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
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

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
//ORDERS-=======================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllOrderDocs() async {
  final orders =
      await FirebaseFirestore.instance.collection(Collections.orders).get();
  return orders.docs.map((order) => order as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllClientOrderDocs(String clientID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.clientID, isEqualTo: clientID)
      .get();
  return orders.docs.map((order) => order as DocumentSnapshot).toList();
}
