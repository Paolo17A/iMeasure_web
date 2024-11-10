import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/gallery_provider.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/utils/firebase_util.dart';
import 'package:imeasure/utils/go_router_util.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/top_navigator_widget.dart';

class ViewPortfolioScreen extends ConsumerStatefulWidget {
  const ViewPortfolioScreen({super.key});

  @override
  ConsumerState<ViewPortfolioScreen> createState() =>
      _ViewPortfolioScreenState();
}

class _ViewPortfolioScreenState extends ConsumerState<ViewPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(userDataProvider).setUserType(await getCurrentUserType());
        /*if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }*/
        ref
            .read(galleryProvider)
            .setGalleryDocs(await getAllPortfolioGalleryDocs());
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting all portfolio entries: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(galleryProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: ref.read(userDataProvider).userType == UserTypes.client
          ? topUserNavigator(context, path: GoRoutes.portfolio)
          : null,
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          ref.read(userDataProvider).userType == UserTypes.client
              ? _userWidgets()
              : _adminWidgets()),
    );
  }

  Widget _userWidgets() {
    return Column(
      children: [
        Divider(color: Colors.white),
        Gap(40),
        quicksandWhiteBold('TESTIMONIALS'),
        horizontal5Percent(context,
            child: Wrap(
              children: ref.read(galleryProvider).galleryDocs.map((gallery) {
                final galleryData = gallery.data() as Map<dynamic, dynamic>;
                String imageURL = galleryData[GalleryFields.imageURL];
                return square300NetworkImage(imageURL);
              }).toList(),
            )),
      ],
    );
  }

  Widget _adminWidgets() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leftNavigator(context, path: GoRoutes.gallery),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _backButton(),
                horizontal5Percent(context,
                    child: Column(
                      children: [_portfolioHeader(), _portfolioEntries()],
                    )),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _backButton() {
    return all20Pix(
        child: Row(children: [
      backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.gallery))
    ]));
  }

  Widget _portfolioHeader() {
    return all20Pix(
        child: Row(children: [
      quicksandWhiteBold('Portfolio: ', fontSize: 28),
      Gap(4),
      quicksandCoralRedBold(
          ref.read(galleryProvider).galleryDocs.length.toString(),
          fontSize: 28)
    ]));
  }

  Widget _portfolioEntries() {
    return Center(
        child: ref.read(galleryProvider).galleryDocs.isNotEmpty
            ? Wrap(
                children: ref
                    .read(galleryProvider)
                    .galleryDocs
                    .map((galleryDoc) => _serviceEntry(galleryDoc))
                    .toList(),
              )
            : quicksandWhiteBold('No portfolio entries added yet'));
  }

  Widget _serviceEntry(DocumentSnapshot galleryDoc) {
    final galleryData = galleryDoc.data() as Map<dynamic, dynamic>;
    String title = galleryData[GalleryFields.title];
    String content = galleryData[GalleryFields.content];
    String imageURL = galleryData[GalleryFields.imageURL];
    return all10Pix(
        child: Container(
      width: 400,
      height: 350,
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Image.network(imageURL, width: 180, height: 180, fit: BoxFit.cover),
          Gap(4),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              quicksandWhiteBold(title,
                  textOverflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left),
              quicksandWhiteRegular(content,
                  fontSize: 16,
                  textOverflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left)
            ])
          ]),
          Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              all4Pix(
                child: editEntryButton(context,
                    iconColor: CustomColors.lavenderMist,
                    onPress: () => GoRouter.of(context)
                            .goNamed(GoRoutes.editTestimonial, pathParameters: {
                          PathParameters.galleryID: galleryDoc.id
                        })),
              ),
              all4Pix(
                child: deleteEntryButton(context,
                    iconColor: CustomColors.lavenderMist,
                    onPress: () => displayDeleteEntryDialog(context,
                        message:
                            'Are you sure you wish to delete this gallery entry? ',
                        deleteEntry: () => deleteGalleryDoc(context, ref,
                            galleryID: galleryDoc.id,
                            refreshGalleryFuture:
                                getAllPortfolioGalleryDocs()))),
              ),
            ],
          )
        ],
      ),
    ));
  }
}
