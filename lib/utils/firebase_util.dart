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
import 'package:imeasure/providers/gallery_provider.dart';
import 'package:imeasure/providers/items_provider.dart';
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

Future registerNewUser(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController mobileNumberController,
    required TextEditingController addressController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        mobileNumberController.text.isEmpty ||
        addressController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.com')) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please input a valid email address')));
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('The passwords do not match')));
      return;
    }
    if (passwordController.text.length < 6) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('The password must be at least six characters long')));
      return;
    }
    if (mobileNumberController.text.length != 11 ||
        mobileNumberController.text[0] != '0' ||
        mobileNumberController.text[1] != '9') {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text(
              'The mobile number must be an 11 digit number formatted as: 09XXXXXXXXX')));
      return;
    }
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(), password: passwordController.text);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      UserFields.email: emailController.text.trim(),
      UserFields.password: passwordController.text,
      UserFields.firstName: firstNameController.text.trim(),
      UserFields.lastName: lastNameController.text.trim(),
      UserFields.mobileNumber: mobileNumberController.text,
      UserFields.address: addressController.text.trim(),
      UserFields.userType: UserTypes.client,
      UserFields.profileImageURL: '',
      UserFields.bookmarks: []
    });
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully registered new user')));
    await FirebaseAuth.instance.signOut();
    ref.read(loadingProvider.notifier).toggleLoading(false);

    goRouter.goNamed(GoRoutes.login);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error registering new user: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
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

Future sendResetPasswordEmail(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (!emailController.text.contains('@') ||
      !emailController.text.contains('.com')) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please input a valid email address.')));
    return;
  }
  try {
    FocusScope.of(context).unfocus();
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final filteredUsers = await FirebaseFirestore.instance
        .collection(Collections.users)
        .where(UserFields.email, isEqualTo: emailController.text.trim())
        .get();

    if (filteredUsers.docs.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('There is no user with that email address.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    if (filteredUsers.docs.first.data()[UserFields.userType] !=
        UserTypes.client) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('This feature is for clients only.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text.trim());
    ref.read(loadingProvider.notifier).toggleLoading(false);
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully sent password reset email!')));
    goRouter.goNamed(GoRoutes.login);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sending password reset email: $error')));
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

Future editUserProfile(BuildContext context, WidgetRef ref,
    {required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController addressController,
    required TextEditingController mobileNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        mobileNumberController.text.isEmpty ||
        addressController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }

    if (mobileNumberController.text.length != 11 ||
        mobileNumberController.text[0] != '0' ||
        mobileNumberController.text[1] != '9') {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text(
              'The mobile number must be an 11 digit number formatted as: 09XXXXXXXXX')));
      return;
    }
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      UserFields.firstName: firstNameController.text.trim(),
      UserFields.lastName: lastNameController.text.trim(),
      UserFields.address: addressController.text.trim(),
      UserFields.mobileNumber: mobileNumberController.text.trim()
    });
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully edited your profile.')));
    goRouter.goNamed(GoRoutes.profile);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing user profile: $error')));
  }
}

//==============================================================================
//ITEMS=========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllItemDocs() async {
  final items =
      await FirebaseFirestore.instance.collection(Collections.items).get();
  return items.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllWindowDocs() async {
  final items = await FirebaseFirestore.instance
      .collection(Collections.items)
      .where(ItemFields.itemType, isEqualTo: ItemTypes.window)
      .get();
  return items.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllDoorDocs() async {
  final items = await FirebaseFirestore.instance
      .collection(Collections.items)
      .where(ItemFields.itemType, isEqualTo: ItemTypes.door)
      .get();
  return items.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllRawMaterialDocs() async {
  final items = await FirebaseFirestore.instance
      .collection(Collections.items)
      .where(ItemFields.itemType, isEqualTo: ItemTypes.rawMaterial)
      .get();
  return items.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisItemDoc(String itemID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.items)
      .doc(itemID)
      .get();
}

Future addFurnitureItemEntry(BuildContext context, WidgetRef ref,
    {required String itemType,
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

    final itemReference =
        await FirebaseFirestore.instance.collection(Collections.items).add({
      ItemFields.name: nameController.text.trim(),
      ItemFields.itemType: itemType,
      ItemFields.description: descriptionController.text.trim(),
      ItemFields.minWidth: double.parse(minWidthController.text),
      ItemFields.maxWidth: double.parse(maxWidthController.text),
      ItemFields.minHeight: double.parse(minHeightController.text),
      ItemFields.maxHeight: double.parse(maxHeightController.text),
      ItemFields.isAvailable: true,
      ItemFields.windowFields: windowFields,
      ItemFields.accessoryFields: accessoryFields
    });

    //  Upload Item Images to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.items)
        .child('${itemReference.id}.png');
    final uploadTask =
        storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemReference.id)
        .update({ItemFields.imageURL: downloadURL});
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new item.')));
    if (itemType == ItemTypes.window) {
      goRouter.goNamed(GoRoutes.windows);
    } else if (itemType == ItemTypes.door) {
      goRouter.goNamed(GoRoutes.doors);
    }
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding new item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editFurnitureItemEntry(BuildContext context, WidgetRef ref,
    {required String itemID,
    required String itemType,
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
        .collection(Collections.items)
        .doc(itemID)
        .update({
      ItemFields.name: nameController.text.trim(),
      ItemFields.description: descriptionController.text.trim(),
      ItemFields.minWidth: double.parse(minWidthController.text),
      ItemFields.maxWidth: double.parse(maxWidthController.text),
      ItemFields.minHeight: double.parse(minHeightController.text),
      ItemFields.maxHeight: double.parse(maxHeightController.text),
      ItemFields.windowFields: windowFields,
      ItemFields.accessoryFields: accessoryFields
    });

    //  Upload Item Images to Firebase Storage
    if (ref.read(uploadedImageProvider).uploadedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.items)
          .child('${itemID}.png');
      final uploadTask =
          storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(Collections.items)
          .doc(itemID)
          .update({ItemFields.imageURL: downloadURL});
    }

    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this item.')));
    if (itemType == ItemTypes.window) {
      goRouter.goNamed(GoRoutes.windows);
    } else if (itemType == ItemTypes.door) {
      goRouter.goNamed(GoRoutes.doors);
    }
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future addRawMaterialEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please fill up all required fields.')));
    return;
  }
  if (double.tryParse(priceController.text) == null ||
      double.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Please enter a valid price higher than PHP 0.00')));
    return;
  }
  if (ref.read(uploadedImageProvider).uploadedImage == null) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Please upload a valid image.')));
    return;
  }
  try {
    ref.read(loadingProvider).toggleLoading(true);
    final itemReference =
        await FirebaseFirestore.instance.collection(Collections.items).add({
      ItemFields.itemType: ItemTypes.rawMaterial,
      ItemFields.name: nameController.text.trim(),
      ItemFields.description: descriptionController.text.trim(),
      ItemFields.price: double.parse(priceController.text.trim()),
      ItemFields.isAvailable: true
    });

    //  Upload Item Images to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.items)
        .child('${itemReference.id}.png');
    final uploadTask =
        storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemReference.id)
        .update({ItemFields.imageURL: downloadURL});
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully added new raw material.')));
    ref.read(loadingProvider).toggleLoading(false);
    goRouter.goNamed(GoRoutes.rawMaterial);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding raw material: $error')));
  }
}

Future editRawMaterialEntry(BuildContext context, WidgetRef ref,
    {required String itemID,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController priceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty ||
      descriptionController.text.isEmpty ||
      priceController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Please fill up all required fields.')));
    return;
  }
  if (double.tryParse(priceController.text) == null ||
      double.parse(priceController.text) <= 0) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Please enter a valid price higher than PHP 0.00')));
    return;
  }
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemID)
        .update({
      ItemFields.name: nameController.text.trim(),
      ItemFields.description: descriptionController.text.trim(),
      ItemFields.price: double.parse(priceController.text.trim()),
    });
    if (ref.read(uploadedImageProvider).uploadedImage != null) {
//  Upload Item Images to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.items)
          .child('${itemID}.png');
      final uploadTask =
          storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection(Collections.items)
          .doc(itemID)
          .update({ItemFields.imageURL: downloadURL});
    }

    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully edited this raw material.')));
    ref.read(loadingProvider).toggleLoading(false);
    goRouter.goNamed(GoRoutes.rawMaterial);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this raw material: $error')));
  }
}

Future toggleItemAvailability(BuildContext context, WidgetRef ref,
    {required String itemID,
    required String itemType,
    required bool isAvailable}) async {
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemID)
        .update({ItemFields.isAvailable: !isAvailable});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Successfully ${isAvailable ? 'archived' : 'restored'} this item')));
    if (itemType == ItemTypes.window) {
      ref.read(itemsProvider).setItemDocs(await getAllWindowDocs());
    } else if (itemType == ItemTypes.door) {
      ref.read(itemsProvider).setItemDocs(await getAllDoorDocs());
    } else if (itemType == ItemTypes.rawMaterial) {
      ref.read(itemsProvider).setItemDocs(await getAllRawMaterialDocs());
    }
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error togging item availability: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

//==============================================================================
//WINDOWS=======================================================================
//==============================================================================
/*Future<List<DocumentSnapshot>> getAllWindowDocs() async {
  final windows =
      await FirebaseFirestore.instance.collection(Collections.windows).get();
  return windows.docs.map((window) => window as DocumentSnapshot).toList();
}*/

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

//==============================================================================
//==GALLERY=====================================================================
//==============================================================================

Future<List<DocumentSnapshot>> getAllServiceGalleryDocs() async {
  final gallery = await FirebaseFirestore.instance
      .collection(Collections.galleries)
      .where(GalleryFields.galleryType, isEqualTo: GalleryTypes.service)
      .get();

  return gallery.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllTestimonialGalleryDocs() async {
  final gallery = await FirebaseFirestore.instance
      .collection(Collections.galleries)
      .where(GalleryFields.galleryType, isEqualTo: GalleryTypes.testimonial)
      .get();

  return gallery.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllPortfolioGalleryDocs() async {
  final gallery = await FirebaseFirestore.instance
      .collection(Collections.galleries)
      .where(GalleryFields.galleryType, isEqualTo: GalleryTypes.portfolio)
      .get();

  return gallery.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisGalleryDoc(String galleryID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.galleries)
      .doc(galleryID)
      .get();
}

Future addGalleryDoc(BuildContext context, WidgetRef ref,
    {required String galleryType,
    required TextEditingController titleController,
    required TextEditingController contentController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Please fill up all requiref fields.')));
      return;
    }
    if (ref.read(uploadedImageProvider).uploadedImage == null) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Please select an image to upload.')));
      return;
    }
    ref.read(loadingProvider).toggleLoading(true);
    final galleryReference =
        await FirebaseFirestore.instance.collection(Collections.galleries).add({
      GalleryFields.galleryType: galleryType,
      GalleryFields.title: titleController.text.trim(),
      GalleryFields.content: contentController.text.trim()
    });
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.galleries)
        .child('${galleryReference.id}.png');
    final uploadTask =
        storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();
    FirebaseFirestore.instance
        .collection(Collections.galleries)
        .doc(galleryReference.id)
        .update({GalleryFields.imageURL: downloadURL});
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully added new gallery entry.')));
    goRouter.goNamed(GoRoutes.gallery);
    ref.read(uploadedImageProvider).removeImage();
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding gallery doc: $error')));
  }
}

Future editGalleryDoc(BuildContext context, WidgetRef ref,
    {required String galleryID,
    required TextEditingController titleController,
    required TextEditingController contentController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.galleries)
        .doc(galleryID)
        .update({
      GalleryFields.title: titleController.text.trim(),
      GalleryFields.content: contentController.text.trim(),
    });
    if (ref.read(uploadedImageProvider).uploadedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.galleries)
          .child('$galleryID.png');
      final uploadTask =
          storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      FirebaseFirestore.instance
          .collection(Collections.galleries)
          .doc(galleryID)
          .update({GalleryFields.imageURL: downloadURL});
    }
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully edited this gallery entry.')));
    goRouter.goNamed(GoRoutes.gallery);
    ref.read(uploadedImageProvider).removeImage();
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing gallery doc: $error')));
  }
}

Future deleteGalleryDoc(BuildContext context, WidgetRef ref,
    {required String galleryID,
    required Future<List<DocumentSnapshot>> refreshGalleryFuture}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.galleries)
        .doc(galleryID)
        .delete();
    await FirebaseStorage.instance
        .ref()
        .child(StorageFields.galleries)
        .child('$galleryID.png')
        .delete();
    ref.read(galleryProvider).setGalleryDocs(await refreshGalleryFuture);
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting gallery entry: $error')));
  }
}
