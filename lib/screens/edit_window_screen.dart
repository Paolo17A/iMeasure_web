import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/utils/color_util.dart';

import '../models/window_models.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class EditWindowScreen extends ConsumerStatefulWidget {
  final String windowID;
  const EditWindowScreen({super.key, required this.windowID});

  @override
  ConsumerState<EditWindowScreen> createState() => _AddWindowScreenState();
}

class _AddWindowScreenState extends ConsumerState<EditWindowScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final minHeightController = TextEditingController();
  final maxHeightController = TextEditingController();
  final minWidthController = TextEditingController();
  final maxWidthController = TextEditingController();
  String imageURL = '';

  List<WindowFieldModel> windowFieldModels = [];
  List<WindowAccessoryModel> windowAccessoryModels = [];

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
        final window = await getThisWindowDoc(widget.windowID);
        final windowData = window.data() as Map<dynamic, dynamic>;
        nameController.text = windowData[WindowFields.name];
        descriptionController.text = windowData[WindowFields.description];
        minHeightController.text =
            windowData[WindowFields.minHeight].toString();
        maxHeightController.text =
            windowData[WindowFields.maxHeight].toString();
        minWidthController.text = windowData[WindowFields.minWidth].toString();
        maxWidthController.text = windowData[WindowFields.maxWidth].toString();
        imageURL = windowData[WindowFields.imageURL];

        List<dynamic> windowFields = windowData[WindowFields.windowFields];
        List<dynamic> accessoryFields =
            windowData[WindowFields.accessoryFields];

        for (var windowField in windowFields) {
          WindowFieldModel windowFieldModel = WindowFieldModel();
          windowFieldModel.nameController.text =
              windowField[WindowSubfields.name];
          windowFieldModel.isMandatory =
              windowField[WindowSubfields.isMandatory];
          windowFieldModel.priceBasis = windowField[WindowSubfields.priceBasis];
          windowFieldModel.brownPriceController.text =
              windowField[WindowSubfields.brownPrice].toString();
          windowFieldModel.mattBlackPriceController.text =
              windowField[WindowSubfields.mattBlackPrice].toString();
          windowFieldModel.mattGrayPriceController.text =
              windowField[WindowSubfields.mattGrayPrice].toString();
          windowFieldModel.woodFinishPriceController.text =
              windowField[WindowSubfields.woodFinishPrice].toString();
          windowFieldModel.whitePriceController.text =
              windowField[WindowSubfields.whitePrice].toString();
          windowFieldModels.add(windowFieldModel);
        }

        for (var accessoryField in accessoryFields) {
          WindowAccessoryModel windowAccessoryModel = WindowAccessoryModel();
          windowAccessoryModel.nameController.text =
              accessoryField[WindowAccessorySubfields.name];
          windowAccessoryModel.priceController.text =
              accessoryField[WindowAccessorySubfields.price].toString();
          windowAccessoryModels.add(windowAccessoryModel);
        }
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting window details: $error')));
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
    minWidthController.dispose();
    maxWidthController.dispose();
    minHeightController.dispose();
    maxHeightController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(uploadedImageProvider);
    return Scaffold(
      appBar: appBarWidget(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.windows),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: switchedLoadingContainer(
              ref.read(loadingProvider).isLoading,
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(children: [
                      _backButton(),
                      _editWindowHeaderWidget(),
                      _windowNameWidget(),
                      _windowDescriptionWidget(),
                      Gap(20),
                      Divider(color: CustomColors.midnightBlue),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              _minHeightWidget(),
                              _maxHeightWidget(),
                              _minWidthWidget(),
                              _maxWidthWidget(),
                            ]),
                      ),
                      Gap(20),
                      Divider(color: CustomColors.midnightBlue),
                      _windowFields(),
                      _accessoryFields(),
                      _productImagesWidget(),
                      _submitButtonWidget()
                    ])),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: Row(children: [
        ElevatedButton(
            onPressed: () => GoRouter.of(context).goNamed(GoRoutes.windows),
            child: montserratMidnightBlueBold('BACK'))
      ]),
    );
  }

  Widget _editWindowHeaderWidget() {
    return montserratBlackBold(
      'EDIT WINDOW',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _windowNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: montserratBlackBold('Window Name', fontSize: 24)),
      CustomTextField(
          text: 'Window Name',
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _windowDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: montserratBlackBold('Window Description', fontSize: 24)),
      CustomTextField(
          text: 'Window Description',
          controller: descriptionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _minHeightWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child: montserratBlackBold('Minimum Height (in feet)',
                  fontSize: 24)),
          CustomTextField(
              text: 'Minimum Height',
              controller: minHeightController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _maxHeightWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child: montserratBlackBold('Maximum Height (in feet)',
                  fontSize: 24)),
          CustomTextField(
              text: 'Maximum Length',
              controller: maxHeightController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _minWidthWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child:
                  montserratBlackBold('Minimum Width (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Minimum Width',
              controller: minWidthController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _maxWidthWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child:
                  montserratBlackBold('Maximum Width (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Maximum Width',
              controller: maxWidthController,
              textInputType: TextInputType.number,
              displayPrefixIcon: null),
        ],
      ),
    );
  }

  Widget _windowFields() {
    return vertical20Pix(
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [montserratBlackBold('WINDOW FIELDS', fontSize: 24)]),
          if (windowFieldModels.isNotEmpty)
            ListView.builder(
                shrinkWrap: true,
                itemCount: windowFieldModels.length,
                itemBuilder: (context, index) {
                  return windowParameterWidget(context,
                      nameController: windowFieldModels[index].nameController,
                      isMandatory: windowFieldModels[index].isMandatory,
                      onCheckboxPress: (newVal) {
                        setState(() {
                          windowFieldModels[index].isMandatory = newVal!;
                        });
                      },
                      priceBasis: windowFieldModels[index].priceBasis,
                      onPriceBasisChange: (newVal) {
                        setState(() {
                          windowFieldModels[index].priceBasis = newVal!;
                        });
                      },
                      brownPriceController:
                          windowFieldModels[index].brownPriceController,
                      mattBlackController:
                          windowFieldModels[index].mattBlackPriceController,
                      mattGrayController:
                          windowFieldModels[index].mattGrayPriceController,
                      woodFinishController:
                          windowFieldModels[index].woodFinishPriceController,
                      whitePriceController:
                          windowFieldModels[index].whitePriceController,
                      onRemoveField: () {
                        if (windowFieldModels.length == 1) {
                          return;
                        }
                        setState(() {
                          windowFieldModels.remove(windowFieldModels[index]);
                        });
                      });
                }),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  windowFieldModels.add(WindowFieldModel());
                });
              },
              child:
                  montserratMidnightBlueBold('ADD WINDOW FIELD', fontSize: 15))
        ],
      ),
    );
  }

  Widget _accessoryFields() {
    return vertical20Pix(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              montserratBlackBold('ACCESSORY FIELDS', fontSize: 24),
            ],
          ),
          windowAccessoryModels.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: windowAccessoryModels.length,
                  itemBuilder: (context, index) {
                    return windowAccessoryWidget(context,
                        nameController:
                            windowAccessoryModels[index].nameController,
                        priceController: windowAccessoryModels[index]
                            .priceController, onRemoveField: () {
                      setState(() {
                        windowAccessoryModels
                            .remove(windowAccessoryModels[index]);
                      });
                    });
                  })
              : montserratBlackRegular('NO ACCESSORIES'),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  windowAccessoryModels.add(WindowAccessoryModel());
                });
              },
              child: montserratMidnightBlueBold('ADD ACCESSORY FIELD',
                  fontSize: 15))
        ],
      ),
    );
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
                          ref.read(uploadedImageProvider).uploadedImage,
                          () => ref.read(uploadedImageProvider).removeImage()))
                else if (!ref.read(loadingProvider).isLoading &&
                    imageURL.isNotEmpty)
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
        onPressed: () => editWindowEntry(context, ref,
            windowID: widget.windowID,
            nameController: nameController,
            descriptionController: descriptionController,
            minHeightController: minHeightController,
            maxHeightController: maxHeightController,
            minWidthController: minWidthController,
            maxWidthController: maxWidthController,
            windowFieldModels: windowFieldModels,
            windowAccesoryModels: windowAccessoryModels),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: montserratMidnightBlueBold('SUBMIT'),
        ),
      ),
    );
  }
}
