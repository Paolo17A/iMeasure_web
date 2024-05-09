import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/orders_provider.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';
import '../widgets/text_widgets.dart';

class ViewOrdersScreen extends ConsumerStatefulWidget {
  const ViewOrdersScreen({super.key});

  @override
  ConsumerState<ViewOrdersScreen> createState() => _ViewOrdersScreenState();
}

class _ViewOrdersScreenState extends ConsumerState<ViewOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          return;
        }

        ref.read(ordersProvider).setOrderDocs(await getAllOrderDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all orders: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(ordersProvider);
    return Scaffold(
      appBar: appBarWidget(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftNavigator(context, path: GoRoutes.orders),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: switchedLoadingContainer(
                  ref.read(loadingProvider).isLoading,
                  SingleChildScrollView(
                    child: all5Percent(context, child: _ordersContainer()),
                  )))
        ],
      ),
    );
  }

  Widget _ordersContainer() {
    return viewContentContainer(
      context,
      child: Column(
        children: [
          _ordersLabelRow(),
          ref.read(ordersProvider).orderDocs.isNotEmpty
              ? _orderEntries()
              : viewContentUnavailable(context, text: 'NO AVAILABLE ORDERS'),
        ],
      ),
    );
  }

  Widget _ordersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Buyer', 2),
      viewFlexLabelTextCell('Item', 2),
      viewFlexLabelTextCell('Status', 2)
    ]);
  }

  Widget _orderEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(ordersProvider).orderDocs.length,
          itemBuilder: (context, index) {
            final orderData = ref.read(ordersProvider).orderDocs[index].data()
                as Map<dynamic, dynamic>;
            String clientID = orderData[OrderFields.clientID];
            String windowID = orderData[OrderFields.windowID];
            String status = orderData[OrderFields.purchaseStatus];

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
                      future: getThisWindowDoc(windowID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData ||
                            snapshot.hasError) return Container();

                        final itemData =
                            snapshot.data!.data() as Map<dynamic, dynamic>;
                        String name = itemData[WindowFields.name];

                        Color entryColor = CustomColors.ghostWhite;
                        Color backgroundColor = index % 2 == 0
                            ? CustomColors.slateBlue.withOpacity(0.75)
                            : CustomColors.slateBlue;

                        return viewContentEntryRow(context, children: [
                          viewFlexTextCell(formattedName,
                              flex: 2,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexTextCell(name,
                              flex: 2,
                              backgroundColor: backgroundColor,
                              textColor: entryColor),
                          viewFlexActionsCell(
                            [
                              if (status == OrderStatuses.generated)
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () => GoRouter.of(context)
                                                  .goNamed(
                                                      GoRoutes.generatedOrder,
                                                      pathParameters: {
                                                    PathParameters.orderID: ref
                                                        .read(ordersProvider)
                                                        .orderDocs[index]
                                                        .id
                                                  }),
                                          child: montserratMidnightBlueBold(
                                              'SET LABOR COST',
                                              fontSize: 12))
                                    ]),
                              if (status == OrderStatuses.pending)
                                montserratWhiteBold('PENDING PAYMENT')
                              else if (status == OrderStatuses.denied)
                                montserratWhiteBold('PAYMENT DENIED')
                              else if (status == OrderStatuses.processing)
                                ElevatedButton(
                                    onPressed: () => markOrderAsReadyForPickUp(
                                        context, ref,
                                        orderID: ref
                                            .read(ordersProvider)
                                            .orderDocs[index]
                                            .id),
                                    child: montserratMidnightBlueBold(
                                        'MARK AS READY FOR PICK UP',
                                        fontSize: 12))
                              else if (status == OrderStatuses.forPickUp)
                                ElevatedButton(
                                    onPressed: () => markOrderAsPickedUp(
                                        context, ref,
                                        orderID: ref
                                            .read(ordersProvider)
                                            .orderDocs[index]
                                            .id),
                                    child: montserratMidnightBlueBold(
                                        'MARK AS PICKED UP',
                                        fontSize: 12))
                              else if (status == OrderStatuses.pickedUp)
                                montserratWhiteBold('COMPLETED')
                            ],
                            flex: 2,
                            backgroundColor: backgroundColor,
                          ),
                        ]);
                      });
                  //  Item Variables
                });
            //  Client Variables
          }),
    );
  }
}
