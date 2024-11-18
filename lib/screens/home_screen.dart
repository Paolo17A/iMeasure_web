import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/active_clients_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart' as pie;

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/quotation_dialog_util.dart';
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
  List<DocumentSnapshot> itemDocs = [];
  List<DocumentSnapshot> orderDocs = [];
  int usersCount = 0;
  int ordersCount = 0;
  double totalSales = 0;
  double monthlySales = 0;
  Map<String, double> itemNameAndOrderMap = {};

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
          itemDocs = await getAllItemDocs();
          final users = await getAllClientDocs();
          usersCount = users.length;

          orderDocs = await getAllOrderDocs();
          ordersCount = orderDocs.length;
          for (var order in orderDocs) {
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
            String itemID = orderData[OrderFields.itemID];
            DocumentSnapshot? itemDoc =
                itemDocs.where((item) => item.id == itemID).firstOrNull;
            if (itemDoc == null) continue;
            final itemData = itemDoc.data() as Map<dynamic, dynamic>;
            String name = itemData[ItemFields.name];
            if (itemNameAndOrderMap.containsKey(name)) {
              itemNameAndOrderMap[name] = itemNameAndOrderMap[name]! + 1;
            } else {
              itemNameAndOrderMap[name] = 1;
            }
          }
          // Calculate the total count
          double total =
              itemNameAndOrderMap.values.fold(0, (sum, value) => sum + value);

          // Convert each count to a percentage
          itemNameAndOrderMap.updateAll((key, value) => (value / total) * 100);
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
                Gap(40),
                horizontal5Percent(context,
                    child: Column(children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _orderBreakdownPieChart(),
                          _monthlyIncomeBarChart(),
                        ],
                      ),
                      Gap(40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ordersContainer(),
                          ActiveClientsWidget(),
                        ],
                      )
                    ]))
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
          Row(children: [quicksandWhiteRegular(label, fontSize: 16)]),
        ]));
  }

  Widget _orderBreakdownPieChart() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.45,
      child: Column(
        children: [
          quicksandWhiteBold('Sales', fontSize: 20),
          if (itemNameAndOrderMap.isNotEmpty)
            pie.PieChart(
                dataMap: itemNameAndOrderMap,
                chartRadius: 300,
                animationDuration: Duration.zero,
                legendOptions: pie.LegendOptions(
                    legendPosition: pie.LegendPosition.right,
                    legendTextStyle:
                        GoogleFonts.quicksand(color: Colors.white)),
                chartValuesOptions: const pie.ChartValuesOptions(
                    decimalPlaces: 2, showChartValuesInPercentage: true))
          else
            quicksandWhiteBold('NO ORDERS HAVE BEEN MADE YET')
        ],
      ),
    );
  }

  Widget _monthlyIncomeBarChart() {
    Map<int, double> orderSpots = {};
    for (int i = 1; i < 13; i++) {
      orderSpots[i] = 0;
    }
    for (var orderDoc in orderDocs) {
      final orderData = orderDoc.data() as Map<dynamic, dynamic>;
      DateTime dateCreated =
          (orderData[OrderFields.dateCreated] as Timestamp).toDate();
      int month = dateCreated.month;
      orderSpots[month] = orderSpots[month]! + 1;
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          quicksandWhiteBold('Monthly Sales'),
          Gap(20),
          Container(
            height: 275,
            child: LineChart(
                LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                          spots: orderSpots.entries
                              .map((e) =>
                                  FlSpot(e.key.toDouble(), e.value.toDouble()))
                              .toList(),
                          color: CustomColors.emeraldGreen),
                    ],
                    gridData: const FlGridData(
                        show: true, verticalInterval: 1, horizontalInterval: 1),
                    titlesData: const FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 3,
                          getTitlesWidget: bottomTitleWidgets,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          getTitlesWidget: leftTitleWidgets,
                          showTitles: true,
                          interval: 1,
                          reservedSize: 22,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: const Border(
                            bottom:
                                BorderSide(color: Colors.blueGrey, width: 4))),
                    minX: 1,
                    maxX: DateTime.now().month + 1,
                    minY: 0,
                    maxY: 20),
                duration: Duration.zero),
          ),
        ],
      ),
    );
  }

  Widget _ordersContainer() {
    List<DocumentSnapshot> recentOrders = orderDocs.where((order) {
      final orderData = order.data() as Map<dynamic, dynamic>;
      DateTime dateOrdered =
          (orderData[OrderFields.dateCreated] as Timestamp).toDate();
      Duration difference = DateTime.now().difference(dateOrdered);
      return difference.inDays.abs() < 7;
    }).toList();
    recentOrders = recentOrders.take(6).toList();
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Column(
        children: [
          quicksandWhiteBold('RECENT ORDERS'),
          _ordersLabelRow(),
          recentOrders.isNotEmpty
              ? _orderEntries(recentOrders)
              : viewContentUnavailable(context, text: 'NO RECENT ORDERS'),
        ],
      ),
    );
  }

  Widget _ordersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Date Ordered', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('Cost', 2),
      viewFlexLabelTextCell('Status', 2),
      viewFlexLabelTextCell('Quotation', 2),
    ]);
  }

  Widget _orderEntries(List<DocumentSnapshot> recentOrders) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: recentOrders.length,
        itemBuilder: (context, index) {
          final orderData = recentOrders[index].data() as Map<dynamic, dynamic>;
          String clientID = orderData[OrderFields.clientID];
          String windowID = orderData[OrderFields.itemID];
          String status = orderData[OrderFields.orderStatus];
          DateTime dateCreated =
              (orderData[OrderFields.dateCreated] as Timestamp).toDate();
          num itemOverallPrice = orderData[OrderFields.quotation]
              [QuotationFields.itemOverallPrice];

          Map<String, dynamic> quotation =
              orderData[OrderFields.quotation] ?? [];

          return FutureBuilder(
              future: getThisUserDoc(clientID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.hasError) return Container();

                final clientData =
                    snapshot.data!.data() as Map<dynamic, dynamic>;
                String formattedName =
                    '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';

                return FutureBuilder(
                    future: getThisItemDoc(windowID),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          snapshot.hasError) return Container();

                      final itemData =
                          snapshot.data!.data() as Map<dynamic, dynamic>;
                      String name = itemData[WindowFields.name];
                      String itemType = itemData[ItemFields.itemType];
                      Color entryColor = Colors.white;
                      Color backgroundColor = Colors.transparent;
                      List<dynamic> imageURLs = itemData[ItemFields.imageURLs];
                      List<dynamic> accessoryFields =
                          itemData[ItemFields.accessoryFields];
                      return viewContentEntryRow(context, children: [
                        viewFlexTextCell(formattedName,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(
                            DateFormat('MMM dd, yyyy').format(dateCreated),
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(name,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(
                            'PHP ${formatPrice(itemOverallPrice.toDouble())}',
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexTextCell(status,
                            flex: 2,
                            backgroundColor: backgroundColor,
                            textColor: entryColor),
                        viewFlexActionsCell([
                          if (itemType == ItemTypes.window ||
                              itemType == ItemTypes.door)
                            ElevatedButton(
                                onPressed: () {
                                  final mandatoryWindowFields =
                                      quotation[QuotationFields.mandatoryMap];
                                  final optionalWindowFields =
                                      quotation[QuotationFields.optionalMap]
                                          as List<dynamic>;
                                  final color =
                                      quotation[QuotationFields.color];
                                  showCartQuotationDialog(context, ref,
                                      totalOverallPayment: itemOverallPrice,
                                      laborPrice:
                                          quotation[QuotationFields.laborPrice],
                                      mandatoryWindowFields:
                                          mandatoryWindowFields,
                                      optionalWindowFields:
                                          optionalWindowFields,
                                      accessoryFields: accessoryFields,
                                      color: color,
                                      width: quotation[QuotationFields.width],
                                      height: quotation[QuotationFields.height],
                                      imageURLs: imageURLs,
                                      itemName: name);
                                },
                                child:
                                    quicksandWhiteRegular('VIEW', fontSize: 12))
                          else
                            quicksandWhiteBold('N/A')
                        ], flex: 2, backgroundColor: backgroundColor),
                      ]);
                    });
                //  Item Variables
              });
          //  Client Variables
        });
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
    String testimonialURL = '';
    String testimonialURL2 = '';
    String portfolioURL = '';
    String portfolioURL2 = '';

    if (testimonialDocs.isNotEmpty) {
      final testimonialData =
          testimonialDocs.first.data() as Map<dynamic, dynamic>;
      testimonialURL = testimonialData[GalleryFields.imageURL];
      if (testimonialDocs.length > 1) {
        final testimonialData =
            testimonialDocs[1].data() as Map<dynamic, dynamic>;
        testimonialURL2 = testimonialData[GalleryFields.imageURL];
      }
    }
    if (portfolioDocs.isNotEmpty) {
      final portfolioData = portfolioDocs.first.data() as Map<dynamic, dynamic>;
      portfolioURL = portfolioData[GalleryFields.imageURL];
      if (portfolioDocs.length > 1) {
        final portfolioData = portfolioDocs[1].data() as Map<dynamic, dynamic>;
        portfolioURL2 = portfolioData[GalleryFields.imageURL];
      }
    }
    return vertical20Pix(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      if (testimonialURL.isNotEmpty)
        Column(children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square300NetworkImage(testimonialURL),
              if (testimonialDocs.length > 1)
                GestureDetector(
                  onTap: () =>
                      GoRouter.of(context).goNamed(GoRoutes.testimonials),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(testimonialURL2))),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                          child:
                              quicksandWhiteBold('+${testimonialDocs.length}')),
                    ),
                  ),
                )
            ],
          ),
          Gap(4),
          quicksandWhiteBold('TESTIMONIALS'),
        ]),
      if (portfolioURL.isNotEmpty)
        Column(children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              square300NetworkImage(portfolioURL),
              if (portfolioDocs.length > 1)
                GestureDetector(
                  onTap: () => GoRouter.of(context).goNamed(GoRoutes.portfolio),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(portfolioURL2))),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: quicksandWhiteBold('+${portfolioDocs.length}'),
                      ),
                    ),
                  ),
                )
            ],
          ),
          Gap(4),
          quicksandWhiteBold('PORTFOLIO'),
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
                    child: square300NetworkImage(
                        (itemData[ItemFields.imageURLs] as List<dynamic>)
                            .first));
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
          quicksandWhiteBold('Durable.', fontSize: 36),
          quicksandWhiteBold('Stylish.', fontSize: 36),
          quicksandWhiteBold('Timeless.', fontSize: 36)
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
              quicksandWhiteRegular(home, textAlign: TextAlign.justify),
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
                  children:
                      [ImagePaths.home1, ImagePaths.home2, ImagePaths.home3]
                          .map((imagePatb) => all10Pix(
                                  child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: AssetImage(imagePatb))),
                              )))
                          .toList()),
            ))
        ],
      ),
    );
  }
}
