import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/user_data_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';

class ViewGalleryScreen extends ConsumerStatefulWidget {
  const ViewGalleryScreen({super.key});

  @override
  ConsumerState<ViewGalleryScreen> createState() => _ViewGalleryScreenState();
}

class _ViewGalleryScreenState extends ConsumerState<ViewGalleryScreen> {
  List<DocumentSnapshot> allTestimonialDocs = [];
  List<DocumentSnapshot> allPortfolioDocs = [];

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
        if (ref.read(userDataProvider).userType == UserTypes.client) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        allTestimonialDocs = await getAllTestimonialGalleryDocs();
        allPortfolioDocs = await getAllPortfolioGalleryDocs();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting gallery entries: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: switchedLoadingContainer(
          ref.read(loadingProvider).isLoading,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftNavigator(context, path: GoRoutes.gallery),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                    child: all5Percent(context,
                        child: Column(children: [
                          galleryDocsContainer(
                              label: 'Client Testimonials',
                              galleryDocs: allTestimonialDocs,
                              viewFunction: () => GoRouter.of(context)
                                  .goNamed(GoRoutes.testimonials),
                              addFunction: () => GoRouter.of(context)
                                  .goNamed(GoRoutes.addTestimonial)),
                          galleryDocsContainer(
                              label: 'Portfolio',
                              galleryDocs: allPortfolioDocs,
                              viewFunction: () => GoRouter.of(context)
                                  .goNamed(GoRoutes.portfolio),
                              addFunction: () => GoRouter.of(context)
                                  .goNamed(GoRoutes.addPortfolio)),
                        ]))),
              )
            ],
          )),
    );
  }

  Widget galleryDocsContainer(
      {required String label,
      required List<DocumentSnapshot> galleryDocs,
      required Function viewFunction,
      required Function addFunction}) {
    String imageURL = '';
    if (galleryDocs.isNotEmpty) {
      final galleryData = galleryDocs.first.data() as Map<dynamic, dynamic>;
      imageURL = galleryData[GalleryFields.imageURL];
    }
    return all20Pix(
        child: Row(
      children: [
        all20Pix(
            child: SizedBox(
                width: 300,
                child: quicksandWhiteBold(label,
                    fontSize: 24, textAlign: TextAlign.left))),
        GestureDetector(
          onTap: () => viewFunction(),
          child: Container(
              height: 150,
              width: 200,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  image: imageURL.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageURL), fit: BoxFit.cover)
                      : null),
              child: Container(
                color:
                    imageURL.isNotEmpty ? Colors.black.withOpacity(0.7) : null,
                child: Center(
                  child: quicksandWhiteRegular(imageURL.isNotEmpty
                      ? '+ ${galleryDocs.length}'
                      : 'No entries added yet'),
                ),
              )),
        ),
        Container(
          height: 150,
          width: 200,
          color: Colors.grey,
          child: TextButton(
              onPressed: () => addFunction(),
              child: quicksandWhiteRegular('Add new')),
        )
      ],
    ));
  }
}
