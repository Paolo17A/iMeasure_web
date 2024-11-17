import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class AddRawMaterialScreen extends ConsumerStatefulWidget {
  const AddRawMaterialScreen({super.key});

  @override
  ConsumerState<AddRawMaterialScreen> createState() =>
      _AddRawMaterialScreenState();
}

class _AddRawMaterialScreenState extends ConsumerState<AddRawMaterialScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goRouter = GoRouter.of(context);
      try {
        ref.read(uploadedImageProvider).removeImage();
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future<void> _pickImages() async {
    List<Uint8List>? pickedFiles = await ImagePickerWeb.getMultiImagesAsBytes();
    if (ref.read(uploadedImageProvider).uploadedImages.length +
            pickedFiles!.length >
        5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You may only upload a maximum of 5 images.')));
      return;
    }
    ref.read(uploadedImageProvider.notifier).addImages(pickedFiles);
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(uploadedImageProvider);
    return Scaffold(
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftNavigator(context, path: GoRoutes.windows),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _backButton(),
                    horizontal5Percent(context,
                        child: Column(children: [
                          _newWindowHeaderWidget(),
                          _rawMaterialNameWidget(),
                          _rawMaterialDescriptionWidget(),
                          _rawMaterialPriceWidget(),
                          Divider(color: CustomColors.lavenderMist),
                          _productImagesWidget(),
                          _submitButtonWidget()
                        ])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return all20Pix(
      child: Row(children: [
        backButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.rawMaterial))
      ]),
    );
  }

  Widget _newWindowHeaderWidget() {
    return quicksandWhiteBold(
      'NEW RAW MATERIAL',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _rawMaterialNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: quicksandWhiteBold('Raw Material Name', fontSize: 24)),
      CustomTextField(
          text: 'Raw Material Name',
          height: 40,
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _rawMaterialDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: quicksandWhiteBold('Raw Material Description', fontSize: 24)),
      CustomTextField(
          text: 'Raw Material Description',
          controller: descriptionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _rawMaterialPriceWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: quicksandWhiteBold('Raw Material Price', fontSize: 24)),
      CustomTextField(
          text: 'Raw Material Price',
          controller: priceController,
          textInputType: TextInputType.number,
          displayPrefixIcon: null),
    ]);
  }

  Widget _productImagesWidget() {
    return vertical20Pix(
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                uploadImageButton('UPLOAD IMAGES', _pickImages),
                if (ref.read(uploadedImageProvider).uploadedImages.isNotEmpty)
                  Wrap(
                      //mainAxisAlignment: MainAxisAlignment.center,
                      children: ref
                          .read(uploadedImageProvider)
                          .uploadedImages
                          .map((imageBytes) => all10Pix(
                                  child: selectedMemoryImageDisplay(imageBytes,
                                      () {
                                ref
                                    .read(uploadedImageProvider)
                                    .removeImageFromList(imageBytes!);
                              })))
                          .toList())
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.lavenderMist),
        onPressed: () => addRawMaterialEntry(context, ref,
            nameController: nameController,
            descriptionController: descriptionController,
            priceController: priceController),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: quicksandBlackBold('SUBMIT'),
        ),
      ),
    );
  }
}
