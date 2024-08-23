import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/widgets/custom_button_widgets.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';

import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class AddPortfolioScreen extends ConsumerStatefulWidget {
  const AddPortfolioScreen({super.key});

  @override
  ConsumerState<AddPortfolioScreen> createState() => _AddPortfolioScreenState();
}

class _AddPortfolioScreenState extends ConsumerState<AddPortfolioScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  Future<void> _pickLogoImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      ref.read(uploadedImageProvider.notifier).addImage(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(userDataProvider).setUserType(await getCurrentUserType());
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error initializing screen: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(uploadedImageProvider);
    return Scaffold(
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          leftNavigator(context, path: GoRoutes.gallery),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                  child: Column(children: [
                _backButton(),
                horizontal5Percent(context,
                    child: Column(
                      children: [
                        _newServiceHeaderWidget(),
                        _titleWidget(),
                        _contentWidget(),
                        _imageWidget(),
                        Gap(40),
                        submitButton(context,
                            label: 'ADD PORTFOLIO',
                            onPress: () => addGalleryDoc(context, ref,
                                galleryType: GalleryTypes.portfolio,
                                titleController: titleController,
                                contentController: contentController))
                      ],
                    ))
              ])))
        ]),
      ),
    );
  }

  Widget _backButton() {
    return all20Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.gallery))
    ]));
  }

  Widget _newServiceHeaderWidget() {
    return quicksandWhiteBold('NEW PORTFOLIO',
        textAlign: TextAlign.center, fontSize: 38);
  }

  Widget _titleWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: quicksandWhiteBold('Title', fontSize: 24)),
      CustomTextField(
          text: 'Title',
          controller: titleController,
          textInputType: TextInputType.text,
          displayPrefixIcon: null),
      const Gap(20)
    ]);
  }

  Widget _contentWidget() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      vertical10Pix(child: quicksandWhiteBold('Content', fontSize: 24)),
      CustomTextField(
          text: 'Content',
          controller: contentController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ]);
  }

  Widget _imageWidget() {
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
