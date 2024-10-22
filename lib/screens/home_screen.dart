import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //  ADMIN
  List<DocumentSnapshot> windowDocs = [];
  int usersCount = 0;
  int ordersCount = 0;
  double totalSales = 0;
  double monthlySales = 0;

  //  GUEST
  List<DocumentSnapshot> itemDocs = [];

  //  USER
  List<DocumentSnapshot> serviceDocs = [];
  List<DocumentSnapshot> testimonialDocs = [];
  List<DocumentSnapshot> portfolioDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          itemDocs = await getAllItemDocs();
          ref.read(loadingProvider.notifier).toggleLoading(false);
          return;
        }

        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          windowDocs = await getAllWindowDocs();
          final users = await getAllClientDocs();
          usersCount = users.length;

          final orders = await getAllOrderDocs();
          ordersCount = orders.length;
          for (var order in orders) {
            final orderData = order.data() as Map<dynamic, dynamic>;
            totalSales += orderData[OrderFields.quotation]
                [QuotationFields.itemOverallPrice];
            if (DateTime.now().month ==
                (orderData[OrderFields.dateCreated] as Timestamp)
                    .toDate()
                    .month) {
              monthlySales += orderData[OrderFields.quotation]
                  [QuotationFields.itemOverallPrice];
            }
          }
        } else if (ref.read(userDataProvider).userType == UserTypes.client) {
          serviceDocs = await getAllServiceGalleryDocs();
          serviceDocs.shuffle();
          testimonialDocs = await getAllTestimonialGalleryDocs();
          testimonialDocs.shuffle();
          portfolioDocs = await getAllPortfolioGalleryDocs();
          portfolioDocs.shuffle();
          itemDocs = await getAllItemDocs();
          itemDocs.shuffle();
        }

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error initializing home: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: !hasLoggedInUser()
          ? topGuestNavigator(context, path: GoRoutes.home)
          : ref.read(userDataProvider).userType == UserTypes.client
              ? topUserNavigator(context, path: GoRoutes.home)
              : null,
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          hasLoggedInUser()
              ? ref.read(userDataProvider).userType == UserTypes.admin
                  ? adminDashboard()
                  : _userWidgets()
              : _guestWidgets()),
    );
  }

  //============================================================================
  //==ADMIN WIDGETS=============================================================
  //============================================================================

  Widget adminDashboard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leftNavigator(context, path: GoRoutes.home),
        SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              children: [
                _platformSummary(),
                //windowsSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _platformSummary() {
    return vertical10Pix(
      child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _platformDataEntry(
                    label: 'Monthly Sales',
                    count: 'PHP ${formatPrice(monthlySales)}',
                    countFontSize: 20,
                    color: CustomColors.forestGreen),
                _platformDataEntry(
                    label: 'Total Income',
                    count: 'PHP ${formatPrice(totalSales)}',
                    countFontSize: 20,
                    color: CustomColors.forestGreen),
                _platformDataEntry(
                    label: 'Orders',
                    count: ordersCount.toString(),
                    color: CustomColors.coralRed),
                _platformDataEntry(
                    label: 'Total users',
                    count: usersCount.toString(),
                    color: CustomColors.deepSkyBlue)
              ])),
    );
  }

  Widget _platformDataEntry(
      {required String label,
      required String count,
      required Color color,
      double countFontSize = 28}) {
    return Container(
        width: 260,
        height: 180,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadiusDirectional.circular(20)),
        padding: EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Padding(
              padding: const EdgeInsets.all(40),
              child: quicksandWhiteBold(count, fontSize: countFontSize)),
          Row(children: [quicksandWhiteRegular(label, fontSize: 16)])
        ]));
  }

  Widget windowsSummary() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(width: 3))),
      child: windowDocs.isNotEmpty
          ? all20Pix(
              child: Wrap(
                spacing: 60,
                runSpacing: 60,
                children:
                    windowDocs.map((window) => _windowEntry(window)).toList(),
              ),
            )
          : Center(
              child: quicksandBlackBold('NO WINDOWS AVAILABLE'),
            ),
    );
  }

  Widget _windowEntry(DocumentSnapshot windowDoc) {
    final windowData = windowDoc.data() as Map<dynamic, dynamic>;
    String name = windowData[WindowFields.name];
    String imageURL = windowData[WindowFields.imageURL];
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              quicksandBlackBold('$name total sales: '),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  quicksandBlackBold('('),
                  FutureBuilder(
                    future: getAllItemOrderDocs(windowDoc.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          snapshot.hasError) return snapshotHandler(snapshot);
                      final windowCount = snapshot.data!.length;
                      return quicksandRedBold(windowCount.toString());
                    },
                  ),
                  quicksandBlackBold(')'),
                ],
              ),
            ],
          ),
          Gap(4),
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(imageURL), fit: BoxFit.cover)),
          ),
        ],
      ),
    );
  }

  //============================================================================
  //==USER WIDGETS==============================================================
  //============================================================================
  Widget _userWidgets() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
          child: Column(
        children: [
          Divider(),
          horizontal5Percent(context,
              child: Column(
                children: [
                  _heritageBanner(),
                  _gallery(),
                  _productsAndItems(),
                ],
              ))
        ],
      )),
    );
  }

  Widget _heritageBanner() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(ImagePaths.heritageBackground),
              fit: BoxFit.cover)),
      padding: EdgeInsets.all(20),
      child: Center(
          child: itcBaumansWhiteBold('HERITAGE ALUMINUM SALES CORPORATION',
              fontSize: 36)),
    );
  }

  Widget _gallery() {
    String serviceURL = '';
    String testimonialURL = '';
    String portfolioURL = '';
    if (serviceDocs.isNotEmpty) {
      final serviceData = serviceDocs.first.data() as Map<dynamic, dynamic>;
      serviceURL = serviceData[GalleryFields.imageURL];
    }
    if (testimonialDocs.isNotEmpty) {
      final testimonialData =
          testimonialDocs.first.data() as Map<dynamic, dynamic>;
      testimonialURL = testimonialData[GalleryFields.imageURL];
    }
    if (portfolioDocs.isNotEmpty) {
      final portfolioData = portfolioDocs.first.data() as Map<dynamic, dynamic>;
      portfolioURL = portfolioData[GalleryFields.imageURL];
    }
    return vertical20Pix(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      if (serviceURL.isNotEmpty)
        Column(children: [
          quicksandWhiteBold('SERVICES'),
          Gap(4),
          square300NetworkImage(serviceURL)
        ]),
      if (testimonialURL.isNotEmpty)
        Column(children: [
          quicksandWhiteBold('TESTIMONIALS'),
          Gap(4),
          square300NetworkImage(testimonialURL)
        ]),
      if (portfolioURL.isNotEmpty)
        Column(children: [
          quicksandWhiteBold('PORTFOLIO'),
          Gap(4),
          square300NetworkImage(portfolioURL)
        ]),
    ]));
  }

  Widget _productsAndItems() {
    return vertical20Pix(
      child: Column(
        children: [
          Row(
            children: [
              Flexible(child: Divider()),
              quicksandWhiteRegular('Products and Items'),
              Flexible(child: Divider()),
            ],
          ),
          Gap(40),
          Wrap(
              spacing: 40,
              runSpacing: 40,
              children: itemDocs.take(6).map((itemDoc) {
                final itemData = itemDoc.data() as Map<dynamic, dynamic>;
                String itemType = itemData[ItemFields.itemType];
                return GestureDetector(
                    onTap: () {
                      if (itemType == ItemTypes.window) {
                        GoRouter.of(context).goNamed(GoRoutes.selectedWindow,
                            pathParameters: {
                              PathParameters.itemID: itemDoc.id
                            });
                      } else if (itemType == ItemTypes.door) {
                        GoRouter.of(context).goNamed(GoRoutes.selectedDoor,
                            pathParameters: {
                              PathParameters.itemID: itemDoc.id
                            });
                      } else if (itemType == ItemTypes.rawMaterial) {
                        addRawMaterialToCart(context, ref, itemID: itemDoc.id);
                      }
                    },
                    child:
                        square300NetworkImage(itemData[ItemFields.imageURL]));
              }).toList())
        ],
      ),
    );
  }

  //============================================================================
  //==GUEST WIDGETS=============================================================
  //============================================================================
  Widget _guestWidgets() {
    return Container(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Divider(),
              horizontal5Percent(context,
                  child: Column(
                    children: [
                      _cleanMoistureCare(),
                      _samples(),
                    ],
                  ))
            ],
          ),
        ));
  }

  Widget _cleanMoistureCare() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(ImagePaths.heritageBackground),
              fit: BoxFit.cover)),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          quicksandWhiteBold('Clean.', fontSize: 36),
          quicksandWhiteBold('Moisture.', fontSize: 36),
          quicksandWhiteBold('Care.', fontSize: 36)
        ],
      ),
    );
  }

  Widget _samples() {
    return vertical10Pix(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              child: Column(
            children: [
              quicksandWhiteRegular(
                  loremIpsum.substring(0, (loremIpsum.length / 2).floor()),
                  textAlign: TextAlign.justify),
              submitButton(context,
                  label: 'SHOP NOW',
                  onPress: () => GoRouter.of(context).goNamed(GoRoutes.login))
            ],
          )),
          if (itemDocs.isNotEmpty)
            Flexible(
                child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: itemDocs.take(3).map((item) {
                  final itemData = item.data() as Map<dynamic, dynamic>;
                  String imageURL = itemData[ItemFields.imageURL];
                  return all10Pix(
                      child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.fill, image: NetworkImage(imageURL))),
                  ));
                }).toList(),
              ),
            ))
        ],
      ),
    );
  }
}
