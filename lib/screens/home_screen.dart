import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:pie_chart/pie_chart.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/left_navigator_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //  ADMIN
  int usersCount = 0;
  int windowsCount = 0;
  int ordersCount = 0;
  double totalSales = 0;
  Map<String, double> paymentBreakdown = {
    TransactionStatuses.approved: 0,
    TransactionStatuses.pending: 0,
    TransactionStatuses.denied: 0
  };

  Map<String, double> orderBreakdown = {
    OrderStatuses.pending: 0,
    OrderStatuses.processing: 0,
    OrderStatuses.denied: 0,
    OrderStatuses.forPickUp: 0,
    OrderStatuses.pickedUp: 0
  };

  //  LOG-IN
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);

        final users = await getAllClientDocs();
        usersCount = users.length;
        final windows = await getAllWindowDocs();
        windowsCount = windows.length;
        final orders = await getAllOrderDocs();
        ordersCount = orders.length;
        for (var order in orders) {
          final orderData = order.data() as Map<dynamic, dynamic>;
          final status = orderData[OrderFields.purchaseStatus];
          if (status == OrderStatuses.pending) {
            orderBreakdown[OrderStatuses.pending] =
                orderBreakdown[OrderStatuses.pending]! + 1;
          } else if (status == OrderStatuses.processing) {
            orderBreakdown[OrderStatuses.processing] =
                orderBreakdown[OrderStatuses.processing]! + 1;
          } else if (status == OrderStatuses.denied) {
            orderBreakdown[OrderStatuses.denied] =
                orderBreakdown[OrderStatuses.denied]! + 1;
          } else if (status == OrderStatuses.forPickUp) {
            orderBreakdown[OrderStatuses.forPickUp] =
                orderBreakdown[OrderStatuses.forPickUp]! + 1;
          } else if (status == OrderStatuses.pickedUp) {
            orderBreakdown[OrderStatuses.pickedUp] =
                orderBreakdown[OrderStatuses.pickedUp]! + 1;
          }
        }

        final transactionDocs = await getAllTransactionDocs();
        for (var transaction in transactionDocs) {
          final transactionData = transaction.data() as Map<dynamic, dynamic>;
          final status = transactionData[TransactionFields.paymentStatus];
          if (status == TransactionStatuses.pending) {
            paymentBreakdown[TransactionStatuses.pending] =
                paymentBreakdown[TransactionStatuses.pending]! + 1;
          } else if (status == TransactionStatuses.approved) {
            paymentBreakdown[TransactionStatuses.approved] =
                paymentBreakdown[TransactionStatuses.approved]! + 1;
            totalSales += transactionData[TransactionFields.paidAmount];
          } else if (status == TransactionStatuses.denied) {
            paymentBreakdown[TransactionStatuses.denied] =
                paymentBreakdown[TransactionStatuses.denied]! + 1;
          }
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
    return Scaffold(
      appBar: appBarWidget(),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          SingleChildScrollView(
              child: Center(
                  child: hasLoggedInUser()
                      ? adminDashboard()
                      : _logInContainer()))),
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
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: switchedLoadingContainer(
              ref.read(loadingProvider).isLoading,
              SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(
                      children: [
                        _platformSummary(),
                        _analyticsBreakdown(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [_paymentStatuses(), _orderStatuses()])
                      ],
                    )),
              )),
        )
      ],
    );
  }

  Widget _platformSummary() {
    //String topRatedName = '';
    //String bestSellerName = '';

    return vertical10Pix(
      child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CustomColors.slateBlue,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            montserratWhiteBold(
                'OVERALL TOTAL WINDOW SALES: PHP ${totalSales.toStringAsFixed(2)}',
                fontSize: 30),
            /*montserratWhiteBold(
                'Best Selling Product: ${bestSellerName.isNotEmpty ? bestSellerName : 'N/A'}',
                fontSize: 18)*/
          ])),
    );
  }

  Widget _analyticsBreakdown() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.slateBlue,
        ),
        child: Wrap(
          spacing: MediaQuery.of(context).size.width * 0.01,
          runSpacing: MediaQuery.of(context).size.height * 0.01,
          alignment: WrapAlignment.spaceEvenly,
          runAlignment: WrapAlignment.spaceEvenly,
          children: [
            analyticReportWidget(context,
                count: usersCount.toString(),
                demographic: 'Registered Users',
                displayIcon: const Icon(Icons.person),
                onPress: () => GoRouter.of(context).goNamed(GoRoutes.users)),
            analyticReportWidget(context,
                count: windowsCount.toString(),
                demographic: 'Available Windows',
                displayIcon: const Icon(Icons.window_outlined),
                onPress: () => GoRouter.of(context).goNamed(GoRoutes.windows)),
            analyticReportWidget(context,
                count: ordersCount.toString(),
                demographic: 'Orders',
                displayIcon: const Icon(Icons.delivery_dining),
                onPress: () => GoRouter.of(context).goNamed(GoRoutes.orders)),
          ],
        ),
      ),
    );
  }

  Widget _paymentStatuses() {
    return breakdownContainer(context,
        child: Column(
          children: [
            montserratBlackBold('TRANSACTION STATUSES'),
            PieChart(
                dataMap: paymentBreakdown,
                colorList: [
                  CustomColors.midnightBlue,
                  CustomColors.slateBlue,
                  CustomColors.powderBlue
                ],
                chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }

  Widget _orderStatuses() {
    return breakdownContainer(context,
        child: Column(
          children: [
            montserratBlackBold('ORDER STATUSES'),
            PieChart(
                dataMap: orderBreakdown,
                colorList: [
                  CustomColors.flaxen,
                  CustomColors.midnightBlue,
                  CustomColors.slateBlue,
                  CustomColors.powderBlue,
                  CustomColors.skyBlue,
                ],
                chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }

  Widget _logInContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: roundedSlateBlueContainer(context,
          child: Column(
            children: [
              vertical20Pix(child: montserratWhiteBold('LOG-IN', fontSize: 40)),
              CustomTextField(
                  text: 'Email Address',
                  controller: emailController,
                  textInputType: TextInputType.emailAddress,
                  displayPrefixIcon: const Icon(Icons.email)),
              const Gap(16),
              CustomTextField(
                text: 'Password',
                controller: passwordController,
                textInputType: TextInputType.visiblePassword,
                displayPrefixIcon: const Icon(Icons.lock),
                onSearchPress: () => logInUser(context, ref,
                    emailController: emailController,
                    passwordController: passwordController),
              ),
              submitButton(context,
                  label: 'LOG-IN',
                  onPress: () => logInUser(context, ref,
                      emailController: emailController,
                      passwordController: passwordController)),
            ],
          )),
    );
  }
}
