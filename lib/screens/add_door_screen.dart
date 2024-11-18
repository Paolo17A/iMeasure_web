import 'dart:typed_data';

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

class AddDoorScreen extends ConsumerStatefulWidget {
  const AddDoorScreen({super.key});

  @override
  ConsumerState<AddDoorScreen> createState() => _AddDoorScreenState();
}

class _AddDoorScreenState extends ConsumerState<AddDoorScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final minHeightController = TextEditingController();
  final maxHeightController = TextEditingController();
  final minWidthController = TextEditingController();
  final maxWidthController = TextEditingController();
  bool hasGlass = false;
  String correspondingModel = '';

  List<WindowFieldModel> windowFieldModels = [WindowFieldModel()];
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
        ref.read(uploadedImageProvider).resetImages();
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
                          _hasGlassCheckbox(),
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
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.doors))
      ]),
    );
  }

  Widget _newWindowHeaderWidget() {
    return quicksandWhiteBold(
      'NEW DOOR',
      textAlign: TextAlign.center,
      fontSize: 38,
    );
  }

  Widget _windowNameWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: quicksandWhiteBold('Door Name', fontSize: 24)),
      CustomTextField(
          text: 'Door Name',
          height: 40,
          controller: nameController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _hasGlassCheckbox() {
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        vertical10Pix(child: quicksandWhiteBold('Has Glass', fontSize: 24)),
        Checkbox(
            value: hasGlass,
            checkColor: Colors.white,
            focusColor: Colors.white,
            onChanged: (newVal) {
              setState(() {
                hasGlass = newVal!;
              });
            })
      ]),
    );
  }

  Widget _windowDescriptionWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(
          child: quicksandWhiteBold('Door Description', fontSize: 24)),
      CustomTextField(
          text: 'Door Description',
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
              AvailableModels.series900,
              AvailableModels.series38Awning,
              AvailableModels.series38w1Panel,
              AvailableModels.series38w2Panel,
              AvailableModels.series798w2Panel,
              AvailableModels.series798w4Panel,
              AvailableModels.series900Door,
              AvailableModels.aluminimDoorBathDoor,
              AvailableModels.aluminumDoorGlassDoor,
              AvailableModels.singleSwingDoor,
              AvailableModels.doubleSwingDoorGlass,
              AvailableModels.kitchenCabinet,
              AvailableModels.screenDoor,
            ], 'Select a corresponding 3D model', false),
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
              text: 'Maximum Height',
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

  Widget _productImagesWidget() {
    return vertical20Pix(
      child: SizedBox(
        width: double.infinity,
        child: Column(
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
                              child: selectedMemoryImageDisplay(imageBytes, () {
                            ref
                                .read(uploadedImageProvider)
                                .removeImageFromList(imageBytes!);
                          })))
                      .toList())
          ],
        ),
      ),
    );
  }

  Widget _windowFields() {
    return vertical20Pix(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              quicksandWhiteBold('DOOR FIELDS', fontSize: 24),
            ],
          ),
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
              child: quicksandBlackBold('ADD DOOR FIELD', fontSize: 15))
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
          if (windowAccessoryModels.isNotEmpty)
            ListView.builder(
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
                }),
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

  Widget _submitButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.lavenderMist),
        onPressed: () => addFurnitureItemEntry(context, ref,
            itemType: ItemTypes.door,
            nameController: nameController,
            descriptionController: descriptionController,
            minHeightController: minHeightController,
            maxHeightController: maxHeightController,
            minWidthController: minWidthController,
            maxWidthController: maxWidthController,
            windowFieldModels: windowFieldModels,
            windowAccesoryModels: windowAccessoryModels,
            correspondingModel: correspondingModel,
            hasGlass: hasGlass),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: quicksandBlackBold('SUBMIT'),
        ),
      ),
    );
  }
}
