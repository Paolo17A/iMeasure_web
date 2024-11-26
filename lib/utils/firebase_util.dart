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
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/appointments_provider.dart';
import 'package:imeasure/providers/gallery_provider.dart';
import 'package:imeasure/providers/items_provider.dart';
import 'package:imeasure/providers/orders_provider.dart';
import 'package:imeasure/providers/transactions_provider.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/utils/quotation_dialog_util.dart';

import '../models/window_models.dart';
import '../providers/cart_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/profile_image_url_provider.dart';
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
      UserFields.bookmarks: [],
      UserFields.lastActive: DateTime.now()
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
    if (userData[UserFields.email] != emailController.text) {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({UserFields.email: emailController.text});
    }
    if (userData[UserFields.userType] == UserTypes.client) {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({UserFields.lastActive: DateTime.now()});
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
    required TextEditingController mobileNumberController,
    required TextEditingController emailAddressController}) async {
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
    final userDoc = await getCurrentUserDoc();
    final userData = userDoc.data() as Map<dynamic, dynamic>;
    if (emailAddressController.text != userData[UserFields.email]) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userData[UserFields.email],
          password: userData[UserFields.password]);
      await FirebaseAuth.instance.currentUser!
          .verifyBeforeUpdateEmail(emailAddressController.text.trim());

      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'A verification email has been sent to the new email address')));
    }
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

Future uploadProfilePicture(BuildContext context, WidgetRef ref) async {
  try {
    final selectedXFile = await ImagePickerWeb.getImageAsBytes();
    if (selectedXFile == null) {
      return;
    }
    //  Upload proof of employment to Firebase Storage
    ref.read(loadingProvider).toggleLoading(true);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.profilePics)
        .child('${FirebaseAuth.instance.currentUser!.uid}.png');
    final uploadTask = storageRef.putData(selectedXFile);
    final taskSnapshot = await uploadTask;
    final String downloadURL = await taskSnapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({UserFields.profileImageURL: downloadURL});
    ref.read(profileImageURLProvider).setImageURL(downloadURL);
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading new profile picture: $error')));
    ref.read(loadingProvider).toggleLoading(false);
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

Future<List<DocumentSnapshot>> getSelectedItemDocs(
    List<dynamic> itemIDs) async {
  if (itemIDs.isEmpty) return [];
  final items = await FirebaseFirestore.instance
      .collection(Collections.items)
      .where(FieldPath.documentId, whereIn: itemIDs)
      .get();
  return items.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> searchForTheseItems(String input) async {
  String searchInput = input.toLowerCase().trim();
  final items =
      await FirebaseFirestore.instance.collection(Collections.items).get();
  List<DocumentSnapshot> filteredItems = items.docs.where((item) {
    final itemData = item.data() as Map<dynamic, dynamic>;
    String name = itemData[ItemFields.name].toString().toLowerCase();
    String itemType = itemData[ItemFields.itemType].toString().toLowerCase();
    return name.contains(searchInput) || itemType.contains(searchInput);
  }).toList();
  return filteredItems;
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
    required List<WindowAccessoryModel> windowAccesoryModels,
    required String correspondingModel,
    required bool hasGlass}) async {
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
  if (ref.read(uploadedImageProvider).uploadedImages.isEmpty) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please upload at least one item image.')));
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
      ItemFields.accessoryFields: accessoryFields,
      ItemFields.correspondingModel:
          correspondingModel == 'N/A' ? '' : correspondingModel,
      ItemFields.hasGlass: hasGlass
    });

    //  Upload Item Images to Firebase Storage
    List<String> downloadURLs = [];
    for (var imageByte in ref.read(uploadedImageProvider).uploadedImages) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.items)
          .child(itemReference.id)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(imageByte!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      downloadURLs.add(downloadURL);
    }
    // final storageRef = FirebaseStorage.instance
    //     .ref()
    //     .child(StorageFields.items)
    //     .child('${itemReference.id}.png');
    // final uploadTask =
    //     storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    // final taskSnapshot = await uploadTask;
    // final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemReference.id)
        .update({ItemFields.imageURLs: downloadURLs});
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
    required List<WindowAccessoryModel> windowAccesoryModels,
    required String correspondingModel,
    required List<dynamic> imageURLs,
    required bool hasGlass}) async {
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
      ItemFields.accessoryFields: accessoryFields,
      ItemFields.correspondingModel:
          correspondingModel == 'N/A' ? '' : correspondingModel,
      ItemFields.hasGlass: hasGlass
    });

    //  Upload Item Images to Firebase Storage
    List<dynamic> downloadURLs = imageURLs;
    if (ref.read(uploadedImageProvider).uploadedImages.isNotEmpty) {
      for (var itemByte in ref.read(uploadedImageProvider).uploadedImages) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child(StorageFields.items)
            .child(itemID)
            .child('${generateRandomHexString(6)}.png');
        final uploadTask = storageRef.putData(itemByte!);
        final taskSnapshot = await uploadTask;
        final downloadURL = await taskSnapshot.ref.getDownloadURL();
        downloadURLs.add(downloadURL);
      }
    }
    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemID)
        .update({ItemFields.imageURLs: downloadURLs});

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
  if (ref.read(uploadedImageProvider).uploadedImages.isEmpty) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please upload at least one item image.')));
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
    List<dynamic> downloadURLs = [];
    for (var bytes in ref.read(uploadedImageProvider).uploadedImages) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.items)
          .child(itemReference.id)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(bytes!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      downloadURLs.add(downloadURL);
    }

    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemReference.id)
        .update({ItemFields.imageURLs: downloadURLs});
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
    required TextEditingController priceController,
    required List<dynamic> imageURLs}) async {
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

    List<dynamic> downloadURLs = imageURLs;
    for (var bytes in ref.read(uploadedImageProvider).uploadedImages) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.items)
          .child(itemID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(bytes!);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      downloadURLs.add(downloadURL);
    }
    await FirebaseFirestore.instance
        .collection(Collections.items)
        .doc(itemID)
        .update({ItemFields.imageURLs: downloadURLs});

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

Future<List<DocumentSnapshot>> getAllUserTransactionDocs() async {
  final transactions = await FirebaseFirestore.instance
      .collection(Collections.transactions)
      .where(TransactionFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  return transactions.docs
      .map((transaction) => transaction as DocumentSnapshot)
      .toList();
}

Future<List<DocumentSnapshot>> getAllVerifiedTransactionDocs() async {
  final transactions = await FirebaseFirestore.instance
      .collection(Collections.transactions)
      .where(TransactionFields.paymentVerified, isEqualTo: true)
      .get();
  return transactions.docs
      .map((transaction) => transaction as DocumentSnapshot)
      .toList();
}

Future<List<DocumentSnapshot>> getAllUnverifiedTransactionDocs() async {
  final transactions = await FirebaseFirestore.instance
      .collection(Collections.transactions)
      .where(TransactionFields.paymentVerified, isEqualTo: false)
      .get();
  return transactions.docs
      .map((transaction) => transaction as DocumentSnapshot)
      .toList();
}

Future approveThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID, required List<dynamic> orderIDs}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .doc(paymentID)
        .update({
      TransactionFields.dateApproved: DateTime.now(),
      TransactionFields.paymentVerified: true,
      TransactionFields.transactionStatus: TransactionStatuses.approved
    });

    for (var orderID in orderIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.orders)
          .doc(orderID)
          .update({OrderFields.orderStatus: OrderStatuses.processing});
    }

    ref
        .read(transactionsProvider)
        .setTransactionDocs(await getAllUnverifiedTransactionDocs());
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
    {required String paymentID,
    required List<dynamic> orderIDs,
    required TextEditingController denialReasonController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if (denialReasonController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('You must indicate a reason for denying this payment.')));
    return;
  }
  try {
    GoRouter.of(context).pop();
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .doc(paymentID)
        .update({
      TransactionFields.dateApproved: DateTime.now(),
      TransactionFields.paymentVerified: true,
      TransactionFields.transactionStatus: TransactionStatuses.denied,
      TransactionFields.denialReason: denialReasonController.text.trim()
    });
    for (var orderID in orderIDs) {
      await FirebaseFirestore.instance
          .collection(Collections.orders)
          .doc(orderID)
          .update({OrderFields.orderStatus: OrderStatuses.denied});
    }

    ref
        .read(transactionsProvider)
        .setTransactionDocs(await getAllUnverifiedTransactionDocs());
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
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.orderStatus)
      .get();
  return orders.docs.reversed
      .map((order) => order as DocumentSnapshot)
      .toList();
}

Future<List<DocumentSnapshot>> getAllUncompletedOrderDocs() async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.orderStatus, isNotEqualTo: OrderStatuses.completed)
      .get();

  //  REMOVE ALL PAYMENT DENIED
  List<DocumentSnapshot> fileteredOrders = orders.docs.where((order) {
    final orderData = order.data();
    String orderStatus = orderData[OrderFields.orderStatus];
    return orderStatus != OrderStatuses.denied;
  }).toList();
  return fileteredOrders;
}

Future<List<DocumentSnapshot>> getAllCompletedOrderDocs() async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.orderStatus,
          whereIn: [OrderStatuses.completed, OrderStatuses.denied]).get();
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

Future<List<DocumentSnapshot>> getAllClientUncompletedOrderDocs(
    String clientID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.clientID, isEqualTo: clientID)
      .get();
  return orders.docs.where((order) {
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> review = orderData[OrderFields.review];
    return orderData[OrderFields.orderStatus] != OrderStatuses.completed ||
        (orderData[OrderFields.orderStatus] == OrderStatuses.completed &&
            review.isEmpty);
  }).toList();
}

Future<List<DocumentSnapshot>> getAllClientCompletedOrderDocs(
    String clientID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.clientID, isEqualTo: clientID)
      .get();
  return orders.docs.where((order) {
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> review = orderData[OrderFields.review];

    return orderData[OrderFields.orderStatus] == OrderStatuses.completed &&
        review.isNotEmpty;
  }).toList();
}

Future<List<DocumentSnapshot>> getAllItemOrderDocs(String itemID) async {
  final orders = await FirebaseFirestore.instance
      .collection(Collections.orders)
      .where(OrderFields.itemID, isEqualTo: itemID)
      .get();
  return orders.docs.map((order) => order as DocumentSnapshot).toList();
}

Future purchaseSelectedCartItems(BuildContext context, WidgetRef ref,
    {required num paidAmount}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    //  1. Generate a purchase document for the selected cart item
    List<String> orderIDs = [];
    for (var cartItem in ref.read(cartProvider).selectedCartItemIDs) {
      final cartDoc = await getThisCartEntry(cartItem);
      final cartData = cartDoc.data() as Map<dynamic, dynamic>;
      //String itemType = cartData[CartFields.itemID];
      Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];

      DocumentReference orderReference =
          await FirebaseFirestore.instance.collection(Collections.orders).add({
        OrderFields.itemID: cartData[CartFields.itemID],
        OrderFields.clientID: cartData[CartFields.clientID],
        OrderFields.quantity: cartData[CartFields.quantity],
        OrderFields.orderStatus: OrderStatuses.pending,
        OrderFields.dateCreated: DateTime.now(),
        OrderFields.quotation: quotation,
        OrderFields.review: {}
      });

      orderIDs.add(orderReference.id);

      await FirebaseFirestore.instance
          .collection(Collections.cart)
          .doc(cartItem)
          .delete();
    }

    //  2. Generate a payment document in Firestore
    DocumentReference transactionReference = await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .add({
      TransactionFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      TransactionFields.paidAmount: paidAmount,
      TransactionFields.paymentVerified: false,
      TransactionFields.transactionStatus: TransactionStatuses.pending,
      TransactionFields.paymentMethod:
          ref.read(cartProvider).selectedPaymentMethod,
      TransactionFields.dateCreated: DateTime.now(),
      TransactionFields.dateApproved: DateTime(1970),
      TransactionFields.orderIDs: orderIDs,
      TransactionFields.denialReason: ''
    });

    //  2. Upload the proof of payment image to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child(StorageFields.payments)
        .child('${transactionReference.id}.png');
    final uploadTask =
        storageRef.putData(ref.read(uploadedImageProvider).uploadedImage!);
    final taskSnapshot = await uploadTask;
    final downloadURL = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection(Collections.transactions)
        .doc(transactionReference.id)
        .update({TransactionFields.proofOfPayment: downloadURL});

    ref.read(cartProvider).setCartItems(await getCartEntries(context));
    ref.read(cartProvider).resetSelectedCartItems();
    ref.read(uploadedImageProvider).removeImage();
    ref.read(cartProvider).setSelectedPaymentMethod('');
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Successfully settled payment and created purchase order')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error purchasing this cart item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsPendingInstallation(BuildContext context, WidgetRef ref,
    {required String orderID,
    required Map<String, String> orderIDandNameMap}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.orderStatus: OrderStatuses.pendingInstallation});
    ref.read(ordersProvider).setOrderDocs(await getAllUncompletedOrderDocs());
    String sortingMethod = ref.read(ordersProvider).sortingMethod;
    ref
        .read(ordersProvider)
        .setOrderMethodAndSort(sortingMethod, orderIDandNameMap);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked order as pending installation.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking order as pending installation: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsPendingDelivery(BuildContext context, WidgetRef ref,
    {required String orderID,
    required Map<String, String> orderIDandNameMap}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.orderStatus: OrderStatuses.pendingDelivery});
    ref.read(ordersProvider).setOrderDocs(await getAllUncompletedOrderDocs());
    String sortingMethod = ref.read(ordersProvider).sortingMethod;
    ref
        .read(ordersProvider)
        .setOrderMethodAndSort(sortingMethod, orderIDandNameMap);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked order as pending delivery.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking order as pending delivery: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsForInstallation(BuildContext context, WidgetRef ref,
    {required String orderID,
    required Timestamp selectedDate,
    required Map<String, String> orderIDandNameMap}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final order = await getThisOrderDoc(orderID);
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.selectedDate] = selectedDate;
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.orderStatus: OrderStatuses.forInstallation,
      OrderFields.quotation: quotation
    });
    ref.read(ordersProvider).setOrderDocs(await getAllUncompletedOrderDocs());
    String sortingMethod = ref.read(ordersProvider).sortingMethod;
    ref
        .read(ordersProvider)
        .setOrderMethodAndSort(sortingMethod, orderIDandNameMap);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked order as ready for installation.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Error marking order as for installation: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsForDelivery(BuildContext context, WidgetRef ref,
    {required String orderID,
    required Timestamp selectedDate,
    required Map<String, String> orderIDandNameMap}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final order = await getThisOrderDoc(orderID);
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.selectedDate] = selectedDate;
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.orderStatus: OrderStatuses.forDelivery,
      OrderFields.quotation: quotation
    });
    ref.read(ordersProvider).setOrderDocs(await getAllUncompletedOrderDocs());
    String sortingMethod = ref.read(ordersProvider).sortingMethod;
    ref
        .read(ordersProvider)
        .setOrderMethodAndSort(sortingMethod, orderIDandNameMap);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('Successfully marked order as ready for delivery.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking order as for delivery: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsPendingInstallationApproval(
    BuildContext context, WidgetRef ref,
    {required String orderID, required List<DateTime> requestedDates}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    GoRouter.of(context).pop();
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final order = await getThisOrderDoc(orderID);
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.requestedDates] = requestedDates;
    quotation[QuotationFields.selectedDate] = DateTime(1970);
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.quotation: quotation,
      OrderFields.orderStatus: OrderStatuses.installationPendingApproval
    });
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Successfully marked order as pending installation approval.')));
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    List<DocumentSnapshot> orderDocs =
        ref.read(ordersProvider).orderDocs.where((orderDoc) {
      final orderData = orderDoc.data() as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> review = orderData[OrderFields.review];

      return (orderData[OrderFields.orderStatus] != OrderStatuses.completed) ||
          (orderData[OrderFields.orderStatus] == OrderStatuses.completed &&
              review.isEmpty);
    }).toList();
    ref.read(ordersProvider).setOrderDocs(orderDocs);
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error marking order as pending installation approval: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsPendingDeliveryApproval(BuildContext context, WidgetRef ref,
    {required String orderID, required List<DateTime> requestedDates}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    GoRouter.of(context).pop();
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final order = await getThisOrderDoc(orderID);
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.requestedDates] = requestedDates;
    quotation[QuotationFields.selectedDate] = DateTime(1970);
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.quotation: quotation,
      OrderFields.orderStatus: OrderStatuses.deliveryPendingApproval
    });
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Successfully marked order as pending delivery approval.')));
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Error marking order as pending delivery approval: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future cancelOrderDeliveryService(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final order = await getThisOrderDoc(orderID);
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.isRequestingAdditionalService] = false;
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.orderStatus: OrderStatuses.forPickUp,
      OrderFields.quotation: quotation
    });
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).sortFromLatestToEarliest();
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully cancelled additional service.')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error cancelling additional service: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsReadyForPickUp(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.orderStatus: OrderStatuses.forPickUp});
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).sortFromLatestToEarliest();
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
      OrderFields.orderStatus: OrderStatuses.pickedUp,
      OrderFields.datePickedUp: DateTime.now()
    });
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).sortFromLatestToEarliest();
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked order as picked up')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking order as picked up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsInstalled(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.orderStatus: OrderStatuses.installed,
      OrderFields.datePickedUp: DateTime.now()
    });
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).sortFromLatestToEarliest();
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked order as picked up')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking order as picked up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsDelivered(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.orderStatus: OrderStatuses.delivered,
      OrderFields.datePickedUp: DateTime.now()
    });
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).sortFromLatestToEarliest();
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked order as picked up')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error marking order as picked up: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future markOrderAsCompleted(BuildContext context, WidgetRef ref,
    {required String orderID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.orderStatus: OrderStatuses.completed});
    ref.read(ordersProvider).setOrderDocs(await getAllUncompletedOrderDocs());
    ref.read(ordersProvider).sortFromLatestToEarliest();

    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully marked order as completed.')));
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

    final order = await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .get();
    final orderData = order.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = orderData[OrderFields.quotation];
    quotation[QuotationFields.quotationURL] = downloadURL;
    quotation[QuotationFields.laborPrice] = laborPrice;

    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({OrderFields.quotation: quotation});
    ref.read(loadingProvider).toggleLoading(false);
    goRouter.goNamed(GoRoutes.orders);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error setting labor cost and creating quotation document: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

Future reviewThisOrder(BuildContext context, WidgetRef ref,
    {required String orderID,
    required int rating,
    required TextEditingController reviewController,
    required List<Uint8List> reviewImageBytesList}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (rating <= 0 || rating > 6) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Please input a rating between 1 to 5.')));
      return;
    }
    goRouter.pop();

    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.review: {
        ReviewFields.rating: rating,
        ReviewFields.review: reviewController.text.trim(),
        ReviewFields.imageURLs: []
      }
    });
    List<dynamic> downloadURLs = [];
    for (var imageByte in reviewImageBytesList) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.reviews)
          .child(orderID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(imageByte);
      final taskSnapshot = await uploadTask;
      final downloadURL = await taskSnapshot.ref.getDownloadURL();
      downloadURLs.add(downloadURL);
    }
    await FirebaseFirestore.instance
        .collection(Collections.orders)
        .doc(orderID)
        .update({
      OrderFields.review: {
        ReviewFields.rating: rating,
        ReviewFields.review: reviewController.text.trim(),
        ReviewFields.imageURLs: downloadURLs
      }
    });
    ref.read(ordersProvider).setOrderDocs(
        await getAllClientUncompletedOrderDocs(
            FirebaseAuth.instance.currentUser!.uid));
    ref.read(ordersProvider).orderDocs.sort((a, b) {
      DateTime aTime = (a[OrderFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[OrderFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding a review to this order: $error')));
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

//==============================================================================
//==CART========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getCartEntries(BuildContext context) async {
  final cartProducts = await FirebaseFirestore.instance
      .collection(Collections.cart)
      .where(CartFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  return cartProducts.docs.map((doc) => doc as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisCartEntry(String cartID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.cart)
      .doc(cartID)
      .get();
}

Future addFurnitureItemToCart(BuildContext context, WidgetRef ref,
    {required String itemID,
    required String itemType,
    required double width,
    required double height,
    required List<dynamic> mandatoryWindowFields,
    required List<Map<dynamic, dynamic>> optionalWindowFields,
    required List<dynamic> accessoryFields,
    required bool requestingService,
    required TextEditingController streetController,
    required TextEditingController barangayController,
    required TextEditingController municipalityController,
    required TextEditingController zipCodeController,
    required TextEditingController contactNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (!hasLoggedInUser()) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please log-in to your account first.')));
    return;
  }
  if (requestingService &&
      (streetController.text.isEmpty ||
          barangayController.text.isEmpty ||
          municipalityController.text.isEmpty ||
          zipCodeController.text.isEmpty ||
          double.tryParse(zipCodeController.text) == null ||
          contactNumberController.text.isEmpty)) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please provide a valid address and contact number.')));
    return;
  }
  try {
    ref.read(loadingProvider).toggleLoading(true);
    List<Map<dynamic, dynamic>> mandatoryMap = [];
    mandatoryMap.add({
      OrderBreakdownMap.field: 'Glass',
      OrderBreakdownMap.breakdownPrice: calculateGlassPrice(ref,
          width: width.toDouble(), height: height.toDouble())
    });
    for (var windowSubField in mandatoryWindowFields) {
      if (windowSubField[WindowSubfields.priceBasis] == 'HEIGHT') {
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.brownPrice] / 21) * height
            });
            break;
          case WindowColors.white:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.whitePrice] / 21) * height
            });
            break;
          case WindowColors.mattBlack:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattBlackPrice] / 21) * height
            });
            break;
          case WindowColors.mattGray:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattGrayPrice] / 21) * height
            });
            break;
          case WindowColors.woodFinish:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                      height
            });
            break;
        }
      } else if (windowSubField[WindowSubfields.priceBasis] == 'WIDTH') {
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.brownPrice] / 21) * width
            });
            break;
          case WindowColors.white:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.whitePrice] / 21) * width
            });
            break;
          case WindowColors.mattBlack:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattBlackPrice] / 21) * width
            });
            break;
          case WindowColors.mattGray:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattGrayPrice] / 21) * width
            });
            break;
          case WindowColors.woodFinish:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.woodFinishPrice] / 21) * width
            });
            break;
        }
      } else if (windowSubField[WindowSubfields.priceBasis] == 'PERIMETER') {
        num perimeter = (2 * width) + (2 * height);
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter
            });
            break;
          case WindowColors.white:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter
            });
            break;
          case WindowColors.mattBlack:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                      perimeter
            });
            break;
          case WindowColors.mattGray:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                      perimeter
            });
            break;
          case WindowColors.woodFinish:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                      perimeter
            });
            break;
        }
      } else if (windowSubField[WindowSubfields.priceBasis] ==
          'PERIMETER DOUBLED') {
        num perimeter = (4 * width) + (2 * height);
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.brownPrice] / 21) * perimeter
            });
            break;
          case WindowColors.white:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.whitePrice] / 21) * perimeter
            });
            break;
          case WindowColors.mattBlack:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                      perimeter
            });
            break;
          case WindowColors.mattGray:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                      perimeter
            });
            break;
          case WindowColors.woodFinish:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                      perimeter
            });
            break;
        }
      } else if (windowSubField[WindowSubfields.priceBasis] ==
          'STACKED WIDTH') {
        num stackedValue = (2 * height) + (6 * width);
        switch (ref.read(cartProvider).selectedColor) {
          case WindowColors.brown:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.brownPrice] / 21) *
                      stackedValue
            });

            break;
          case WindowColors.white:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.whitePrice] / 21) *
                      stackedValue
            });
            break;
          case WindowColors.mattBlack:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattBlackPrice] / 21) *
                      stackedValue
            });
            break;
          case WindowColors.mattGray:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.mattGrayPrice] / 21) *
                      stackedValue
            });
            break;
          case WindowColors.woodFinish:
            mandatoryMap.add({
              OrderBreakdownMap.field: windowSubField[WindowSubfields.name],
              OrderBreakdownMap.breakdownPrice:
                  (windowSubField[WindowSubfields.woodFinishPrice] / 21) *
                      stackedValue
            });
            break;
        }
      }
    }

    List<Map<dynamic, dynamic>> optionalMap = [];
    for (var windowSubField in optionalWindowFields) {
      if (windowSubField[OptionalWindowFields.isSelected]) {
        optionalMap.add({
          OrderBreakdownMap.field:
              windowSubField[OptionalWindowFields.optionalFields]
                  [WindowFields.name],
          OrderBreakdownMap.breakdownPrice:
              windowSubField[OptionalWindowFields.price]
        });
      }
    }
    double accesoriesPrice = 0;
    for (var accessory in accessoryFields) {
      accesoriesPrice += accessory[WindowAccessorySubfields.price];
    }

    await FirebaseFirestore.instance.collection(Collections.cart).add({
      CartFields.itemID: itemID,
      CartFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      CartFields.quantity: 1,
      CartFields.itemType: itemType,
      CartFields.dateLastModified: DateTime.now(),
      CartFields.quotation: {
        QuotationFields.width: width,
        QuotationFields.height: height,
        QuotationFields.glassType: ref.read(cartProvider).selectedGlassType,
        QuotationFields.color: ref.read(cartProvider).selectedColor,
        QuotationFields.mandatoryMap: mandatoryMap,
        QuotationFields.optionalMap: optionalMap,
        QuotationFields.itemOverallPrice:
            calculateGlassPrice(ref, width: width, height: height) +
                calculateTotalMandatoryPayment(ref,
                    width: width,
                    height: height,
                    mandatoryWindowFields: mandatoryWindowFields) +
                calculateOptionalPrice(optionalWindowFields) +
                accesoriesPrice,
        QuotationFields.laborPrice: 0,
        QuotationFields.quotationURL: '',
        //REQUESTS
        QuotationFields.isRequestingAdditionalService: requestingService,
        QuotationFields.additionalServicePrice: 0,
        QuotationFields.requestAddress:
            '${streetController.text.trim()}, ${barangayController.text.trim()}, ${municipalityController.text.trim()}, ${zipCodeController.text.trim()}',
        QuotationFields.requestContactNumber:
            contactNumberController.text.trim(),
        QuotationFields.requestStatus: '',
        QuotationFields.requestDenialReason: ''
      }
    });

    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully added this item to your cart.')));
    ref.read(loadingProvider).toggleLoading(false);
    goRouter.goNamed(GoRoutes.shop);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding product to cart: $error')));
  }
}

Future addRawMaterialToCart(BuildContext context, WidgetRef ref,
    {required String itemID,
    required bool requestingService,
    required num itemOverallPrice,
    required TextEditingController streetController,
    required TextEditingController barangayController,
    required TextEditingController municipalityController,
    required TextEditingController zipCodeController,
    required TextEditingController contactNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    if (requestingService &&
        (streetController.text.isEmpty ||
            barangayController.text.isEmpty ||
            municipalityController.text.isEmpty ||
            zipCodeController.text.isEmpty ||
            double.tryParse(zipCodeController.text) == null ||
            contactNumberController.text.isEmpty)) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Please provide a valid address and contact number.')));
      return;
    }
    if (ref.read(cartProvider).cartContainsThisItem(itemID)) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('This item is already in your cart.')));
      return;
    }
    final cartDocReference =
        await FirebaseFirestore.instance.collection(Collections.cart).add({
      CartFields.itemID: itemID,
      CartFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      CartFields.quantity: 1,
      CartFields.itemType: ItemTypes.rawMaterial,
      CartFields.dateLastModified: DateTime.now(),
      CartFields.quotation: {
        QuotationFields.isRequestingAdditionalService: requestingService,
        QuotationFields.additionalServicePrice: 0,
        QuotationFields.requestAddress:
            '${streetController.text.trim()}, ${barangayController.text.trim()}, ${municipalityController.text.trim()}, ${zipCodeController.text.trim()}',
        QuotationFields.requestContactNumber:
            contactNumberController.text.trim(),
        QuotationFields.requestStatus: '',
        QuotationFields.itemOverallPrice: itemOverallPrice,
        QuotationFields.requestDenialReason: ''
      }
    });
    ref.read(cartProvider.notifier).addCartItem(await cartDocReference.get());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully added raw material to cart.')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error adding raw material to cart: $error')));
  }
}

void removeCartItem(BuildContext context, WidgetRef ref,
    {required DocumentSnapshot cartDoc}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    await cartDoc.reference.delete();

    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully removed this item from your cart.')));
    ref.read(cartProvider).removeCartItem(cartDoc);
    ref.read(cartProvider).updateCartSubLists();
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error removing cart item: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future changeCartItemQuantity(BuildContext context, WidgetRef ref,
    {required DocumentSnapshot cartEntryDoc,
    required bool isIncreasing}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    final cartEntryData = cartEntryDoc.data() as Map<dynamic, dynamic>;
    int quantity = cartEntryData[CartFields.quantity];
    if (isIncreasing) {
      quantity++;
    } else {
      quantity--;
    }
    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartEntryDoc.id)
        .update({CartFields.quantity: quantity});
    ref.read(cartProvider).setCartItems(await getCartEntries(context));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error changing item quantity: $error')));
  }
}

Future setCartItemLaborPrice(BuildContext context, WidgetRef ref,
    {required String cartID,
    required TextEditingController laborPriceController,
    required bool requestingAdditionalService,
    required bool willGrantInstallation,
    required TextEditingController installationController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (laborPriceController.text.isEmpty ||
        double.tryParse(laborPriceController.text) == null ||
        double.parse(laborPriceController.text) <= 0) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('Pleas input a valid labor price higher than PHP 0.00')));
      return;
    }
    if (requestingAdditionalService &&
        willGrantInstallation &&
        (double.tryParse(installationController.text) == null ||
            double.parse(installationController.text) <= 0)) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Pleas input a valid installation price higher than PHP 0.00')));
      return;
    }
    if (requestingAdditionalService &&
        !willGrantInstallation &&
        installationController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
              'Pleas input a valid reason for denying the installation request')));
      return;
    }
    goRouter.pop();
    ref.read(loadingProvider).toggleLoading(true);
    final cart = await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .get();
    final cartData = cart.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    quotation[QuotationFields.laborPrice] =
        double.parse(laborPriceController.text);
    //  User is requesting both labor and installation
    if (requestingAdditionalService) {
      quotation[QuotationFields.requestStatus] = willGrantInstallation
          ? RequestStatuses.approved
          : RequestStatuses.denied;
      //  Installation request is granted
      if (willGrantInstallation) {
        quotation[QuotationFields.additionalServicePrice] =
            double.parse(installationController.text.trim());
      }
      //  Installation request is denied
      else {
        quotation[QuotationFields.requestDenialReason] =
            installationController.text.trim();
      }
    }
    //  User is only requesting for labor
    else {
      quotation[QuotationFields.requestStatus] = RequestStatuses.approved;
    }

    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .update({
      CartFields.quotation: quotation,
      CartFields.dateLastModified: DateTime.now()
    });
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully set item labor price.')));
    ref
        .read(cartProvider)
        .setCartItems(await getAllCartItemsWithNoLaborPrice());
    bool isChronological = ref.read(cartProvider).isChronological;
    ref.read(cartProvider).setIsChronological(isChronological);
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error setting item labor price: $error')));
  }
}

Future setCartItemDeliveryPrice(BuildContext context, WidgetRef ref,
    {required String cartID,
    required TextEditingController deliveryPriceController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (deliveryPriceController.text.isEmpty ||
        double.tryParse(deliveryPriceController.text) == null ||
        double.parse(deliveryPriceController.text) <= 0) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('Pleas input a valid delivery price higher than PHP 0.00')));
      return;
    }
    goRouter.pop();
    ref.read(loadingProvider).toggleLoading(true);
    final cart = await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .get();
    final cartData = cart.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    quotation[QuotationFields.additionalServicePrice] =
        double.parse(deliveryPriceController.text);
    quotation[QuotationFields.requestStatus] = RequestStatuses.approved;
    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .update({
      CartFields.quotation: quotation,
      CartFields.dateLastModified: DateTime.now()
    });
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully set item delivery price.')));
    ref
        .read(cartProvider)
        .setCartItems(await getAllCartItemsWithNoDeliveryPrice());
    bool isChronological = ref.read(cartProvider).isChronological;
    ref.read(cartProvider).setIsChronological(isChronological);
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error setting item delivery price: $error')));
  }
}

Future denyCartItemDeliveryRequest(BuildContext context, WidgetRef ref,
    {required String cartID,
    required TextEditingController deliveryController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (deliveryController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Pleas input a valid denial reason')));
      return;
    }
    goRouter.pop();
    ref.read(loadingProvider).toggleLoading(true);
    final cart = await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .get();
    final cartData = cart.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    quotation[QuotationFields.requestDenialReason] = deliveryController.text;
    quotation[QuotationFields.requestStatus] = RequestStatuses.denied;
    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .update({
      CartFields.quotation: quotation,
      CartFields.dateLastModified: DateTime.now()
    });
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully denied delivery request')));
    ref
        .read(cartProvider)
        .setCartItems(await getAllCartItemsWithNoDeliveryPrice());
    bool isChronological = ref.read(cartProvider).isChronological;
    ref.read(cartProvider).setIsChronological(isChronological);
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error setting item delivery price: $error')));
  }
}

Future<List<DocumentSnapshot>> getAllCartItemsWithNoLaborPrice() async {
  final cart = await FirebaseFirestore.instance
      .collection(Collections.cart)
      .where(CartFields.itemType,
          whereIn: [ItemTypes.window, ItemTypes.door]).get();
  final filteredCartItems = cart.docs.where((cartDoc) {
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    String requestStatus = quotation[QuotationFields.requestStatus];
    return requestStatus == RequestStatuses.pending &&
        quotation.containsKey(QuotationFields.laborPrice) &&
        quotation[QuotationFields.laborPrice] <= 0;
  }).toList();
  return filteredCartItems;
}

Future<List<DocumentSnapshot>> getAllCartItemsWithNoDeliveryPrice() async {
  final cart = await FirebaseFirestore.instance
      .collection(Collections.cart)
      .where(CartFields.itemType, isEqualTo: ItemTypes.rawMaterial)
      .get();
  final filteredCartItems = cart.docs.where((cartDoc) {
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    String requestStatus = quotation[QuotationFields.requestStatus];
    num additionalServicePrice =
        quotation[QuotationFields.additionalServicePrice];
    return requestStatus == RequestStatuses.pending &&
        additionalServicePrice <= 0;
  }).toList();
  return filteredCartItems;
}

Future requestForAdditionalCosts(BuildContext context, WidgetRef ref,
    {required String cartID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    final cartDoc = await getThisCartEntry(cartID);
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
    quotation[QuotationFields.requestStatus] = RequestStatuses.pending;
    await FirebaseFirestore.instance
        .collection(Collections.cart)
        .doc(cartID)
        .update({
      CartFields.quotation: quotation,
      CartFields.dateLastModified: DateTime.now()
    });
    scaffoldMessenger.showSnackBar(SnackBar(
        content:
            Text('Sucessfully requested for additional cost calculation.')));
    ref.read(cartProvider).setCartItems(await getCartEntries(context));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error requesting for additional costs.')));
  }
}

//==============================================================================
//==APPOINTMENT=================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllAppointments() async {
  final appointments = await FirebaseFirestore.instance
      .collection(Collections.appointments)
      .get();
  return appointments.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getNotPendingAppointments() async {
  final appointments = await FirebaseFirestore.instance
      .collection(Collections.appointments)
      .where(AppointmentFields.appointmentStatus,
          isNotEqualTo: AppointmentStatuses.pending)
      .get();
  return appointments.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getPendingAppointments() async {
  final appointments = await FirebaseFirestore.instance
      .collection(Collections.appointments)
      .where(AppointmentFields.appointmentStatus,
          isEqualTo: AppointmentStatuses.pending)
      .get();
  return appointments.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllUserAppointments() async {
  final appointments = await FirebaseFirestore.instance
      .collection(Collections.appointments)
      .where(AppointmentFields.clientID,
          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get();
  return appointments.docs.map((e) => e as DocumentSnapshot).toList();
}

Future requestForAppointment(BuildContext context, WidgetRef ref,
    {required List<DateTime> requestedDates,
    required TextEditingController streetController,
    required TextEditingController barangayController,
    required TextEditingController municipalityController,
    required TextEditingController zipCodeController,
    required TextEditingController contactNumberController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  if ((streetController.text.isEmpty ||
      barangayController.text.isEmpty ||
      municipalityController.text.isEmpty ||
      zipCodeController.text.isEmpty ||
      double.tryParse(zipCodeController.text) == null ||
      contactNumberController.text.isEmpty)) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please provide a valid address and contact number.')));
    return;
  }
  try {
    GoRouter.of(context).pop();
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance.collection(Collections.appointments).add({
      AppointmentFields.clientID: FirebaseAuth.instance.currentUser!.uid,
      AppointmentFields.proposedDates: requestedDates,
      AppointmentFields.appointmentStatus: AppointmentStatuses.pending,
      AppointmentFields.selectedDate: DateTime.now(),
      AppointmentFields.denialReason: '',
      AppointmentFields.dateCreated: DateTime.now(),
      AppointmentFields.address:
          '${streetController.text.trim()}, ${barangayController.text.trim()}, ${municipalityController.text.trim()}, ${zipCodeController.text.trim()}'
    });
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully requested for an appointment.')));
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error requesting for an appointment.')));
  }
}

Future cancelPendingAppointment(BuildContext context, WidgetRef ref,
    {required String appointmentID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.appointments)
        .doc(appointmentID)
        .update({
      AppointmentFields.appointmentStatus: AppointmentStatuses.cancelled
    });
    ref
        .read(appointmentsProvider)
        .setAppointmentDocs(await getAllUserAppointments());
    ref.read(appointmentsProvider).appointmentDocs.sort((a, b) {
      DateTime aTime = (a[AppointmentFields.dateCreated] as Timestamp).toDate();
      DateTime bTime = (b[AppointmentFields.dateCreated] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully cancelled this appointment.')));
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting pending appointment.')));
  }
}

Future approveThisAppointment(BuildContext context, WidgetRef ref,
    {required String appointmentID, required DateTime selectedDate}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    GoRouter.of(context).pop();
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.appointments)
        .doc(appointmentID)
        .update({
      AppointmentFields.appointmentStatus: AppointmentStatuses.approved,
      AppointmentFields.selectedDate: selectedDate
    });
    ref
        .read(appointmentsProvider)
        .setAppointmentDocs(await getPendingAppointments());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully approved this appointment.')));
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error approved pending appointment.')));
  }
}

Future denyThisAppointment(BuildContext context, WidgetRef ref,
    {required String appointmentID,
    required TextEditingController denialReasonController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    if (denialReasonController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content:
              Text('You must indicate a reason for denying this payment.')));
      return;
    }
    GoRouter.of(context).pop();
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.appointments)
        .doc(appointmentID)
        .update({
      AppointmentFields.appointmentStatus: AppointmentStatuses.denied,
      AppointmentFields.denialReason: denialReasonController.text.trim()
    });
    ref
        .read(appointmentsProvider)
        .setAppointmentDocs(await getPendingAppointments());
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Successfully denied this appointment.')));
    ref.read(loadingProvider).toggleLoading(false);
  } catch (error) {
    ref.read(loadingProvider).toggleLoading(false);
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denied pending appointment.')));
  }
}
