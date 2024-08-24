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
import '../widgets/app_drawer_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class EditRawMaterialScreen extends ConsumerStatefulWidget {
  final String itemID;
  const EditRawMaterialScreen({super.key, required this.itemID});

  @override
  ConsumerState<EditRawMaterialScreen> createState() =>
      _EditRawMaterialScreenState();
}

class _EditRawMaterialScreenState extends ConsumerState<EditRawMaterialScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  String imageURL = '';

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
        final item = await getThisItemDoc(widget.itemID);
        final itemData = item.data() as Map<dynamic, dynamic>;
        nameController.text = itemData[ItemFields.name];
        descriptionController.text = itemData[ItemFields.description];
        priceController.text = itemData[ItemFields.price].toString();
        imageURL = itemData[ItemFields.imageURL];
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      ref.read(uploadedImageProvider.notifier).addImage(pickedFile);
    }
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
      drawer: appDrawer(context, currentPath: GoRoutes.windows),
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
      'EDIT RAW MATERIAL',
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
                uploadImageButton('UPLOAD IMAGE', _pickLogoImage),
                if (ref.read(uploadedImageProvider).uploadedImage != null)
                  vertical10Pix(
                      child: selectedMemoryImageDisplay(
                          ref.read(uploadedImageProvider).uploadedImage, () {
                    ref.read(uploadedImageProvider).removeImage();
                  }))
                else if (imageURL.isNotEmpty)
                  vertical10Pix(child: selectedNetworkImageDisplay(imageURL))
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
        onPressed: () => editRawMaterialEntry(context, ref,
            itemID: widget.itemID,
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
