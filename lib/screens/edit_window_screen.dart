import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/utils/color_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../models/window_models.dart';
import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/dropdown_widget.dart';
import '../widgets/text_widgets.dart';

class EditWindowScreen extends ConsumerStatefulWidget {
  final String itemID;
  const EditWindowScreen({super.key, required this.itemID});

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
  List<dynamic> imageURLs = [];
  String correspondingModel = '';

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
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final item = await getThisItemDoc(widget.itemID);
        final itemData = item.data() as Map<dynamic, dynamic>;
        nameController.text = itemData[ItemFields.name];
        descriptionController.text = itemData[ItemFields.description];
        minHeightController.text = itemData[ItemFields.minHeight].toString();
        maxHeightController.text = itemData[ItemFields.maxHeight].toString();
        minWidthController.text = itemData[ItemFields.minWidth].toString();
        maxWidthController.text = itemData[ItemFields.maxWidth].toString();
        imageURLs = itemData[ItemFields.imageURLs];
        correspondingModel = itemData[ItemFields.correspondingModel];

        List<dynamic> windowFields = itemData[ItemFields.windowFields];
        List<dynamic> accessoryFields = itemData[ItemFields.accessoryFields];

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
        ref.read(uploadedImageProvider).resetImages();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting window details: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      ref.read(uploadedImageProvider).addImage(pickedFile);
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
      body: switchedLoadingContainer(
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
                          _editWindowHeaderWidget(),
                          _windowNameWidget(),
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
                          _windowDescriptionWidget(),
                          _correspondingModelWidget(),
                          Divider(color: CustomColors.lavenderMist),
                          _windowFields(),
                          _accessoryFields(),
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
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.windows))
      ]),
    );
  }

  Widget _editWindowHeaderWidget() {
    return quicksandWhiteBold(
      'EDIT WINDOW',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _windowNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: quicksandWhiteBold('Window Name', fontSize: 24)),
      CustomTextField(
          text: 'Window Name',
          height: 40,
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _windowDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: quicksandWhiteBold('Window Description', fontSize: 24)),
      CustomTextField(
          text: 'Window Description',
          controller: descriptionController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _correspondingModelWidget() {
    return vertical10Pix(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quicksandWhiteBold('Correspoding 3D Model'),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: dropdownWidget(correspondingModel, (newVal) {
              setState(() {
                correspondingModel = newVal!;
              });
            }, [
              'N/A',
              AvailableModels.series38,
              AvailableModels.series798,
              AvailableModels.series900
            ], '', false),
          ),
        ],
      ),
    );
  }

  Widget _minHeightWidget() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vertical10Pix(
              child:
                  quicksandWhiteBold('Minimum Height (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Minimum Height',
              height: 40,
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
              child:
                  quicksandWhiteBold('Maximum Height (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Maximum Length',
              height: 40,
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
                  quicksandWhiteBold('Minimum Width (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Minimum Width',
              height: 40,
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
                  quicksandWhiteBold('Maximum Width (in feet)', fontSize: 24)),
          CustomTextField(
              text: 'Maximum Width',
              height: 40,
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
              children: [quicksandWhiteBold('WINDOW FIELDS', fontSize: 24)]),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.lavenderMist),
              onPressed: () {
                setState(() {
                  windowFieldModels.add(WindowFieldModel());
                });
              },
              child: quicksandBlackBold('ADD WINDOW FIELD', fontSize: 15))
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
              quicksandWhiteBold('ACCESSORY FIELDS', fontSize: 24),
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
              : quicksandWhiteRegular('NO ACCESSORIES'),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.lavenderMist),
              onPressed: () {
                setState(() {
                  windowAccessoryModels.add(WindowAccessoryModel());
                });
              },
              child: quicksandBlackBold('ADD ACCESSORY FIELD', fontSize: 15))
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
                Wrap(children: [
                  if (!ref.read(loadingProvider).isLoading &&
                      imageURLs.isNotEmpty)
                    ...imageURLs
                        .map((imageURL) => all10Pix(
                                child: selectedNetworkImageDisplay(imageURL,
                                    displayDelete: true, onDelete: () {
                              if (imageURLs.length +
                                      ref
                                          .read(uploadedImageProvider)
                                          .uploadedImages
                                          .length ==
                                  1) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'You must have at least one image available for this item ')));
                                return;
                              }
                              setState(() {
                                imageURLs.remove(imageURL);
                              });
                            })))
                        .toList(),
                  if (ref.read(uploadedImageProvider).uploadedImages.isNotEmpty)
                    ...ref
                        .read(uploadedImageProvider)
                        .uploadedImages
                        .map((imageByte) => all10Pix(
                            child: selectedMemoryImageDisplay(
                                imageByte,
                                () => ref
                                    .read(uploadedImageProvider)
                                    .removeImage())))
                        .toList()
                ])
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
        onPressed: () => editFurnitureItemEntry(context, ref,
            itemID: widget.itemID,
            itemType: ItemTypes.window,
            nameController: nameController,
            descriptionController: descriptionController,
            minHeightController: minHeightController,
            maxHeightController: maxHeightController,
            minWidthController: minWidthController,
            maxWidthController: maxWidthController,
            windowFieldModels: windowFieldModels,
            windowAccesoryModels: windowAccessoryModels,
            correspondingModel: correspondingModel,
            imageURLs: imageURLs),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: quicksandBlackBold('SUBMIT'),
        ),
      ),
    );
  }
}
