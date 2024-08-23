import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:imeasure/providers/user_data_provider.dart';
import 'package:imeasure/utils/string_util.dart';
import 'package:imeasure/widgets/app_drawer_widget.dart';
import 'package:imeasure/widgets/left_navigator_widget.dart';
import 'package:imeasure/widgets/text_widgets.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';

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
  Map<String, double> paymentBreakdown = {
    TransactionStatuses.approved: 0,
    TransactionStatuses.pending: 0,
    TransactionStatuses.denied: 0
  };

  Map<String, double> orderBreakdown = {
    OrderStatuses.generated: 0,
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
        if (!hasLoggedInUser()) {
          return;
        }

        ref.read(loadingProvider.notifier).toggleLoading(true);
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          windowDocs = await getAllWindowDocs();

          final users = await getAllClientDocs();
          usersCount = users.length;
          // final windows = await getAllWindowDocs();
          // windowsCount = windows.length;
          final orders = await getAllOrderDocs();
          ordersCount = orders.length;
          /*for (var order in orders) {
          final orderData = order.data() as Map<dynamic, dynamic>;
          final status = orderData[OrderFields.purchaseStatus];
          if (status == OrderStatuses.generated) {
            orderBreakdown[OrderStatuses.generated] =
                orderBreakdown[OrderStatuses.generated]! + 1;
          } else if (status == OrderStatuses.pending) {
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
        }*/

          /*final transactionDocs = await getAllTransactionDocs();
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
          }*/
        } else {}

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
      //appBar: appBarWidget(),
      drawer: hasLoggedInUser()
          ? appDrawer(context, currentPath: GoRoutes.home)
          : null,
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          hasLoggedInUser()
              ? ref.read(userDataProvider).userType == UserTypes.admin
                  ? adminDashboard()
                  : Container()
              : _logInContainer()),
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
                    color: CustomColors.forestGreen),
                _platformDataEntry(
                    label: 'Total Income',
                    count: 'PHP ${formatPrice(totalSales)}',
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
      {required String label, required String count, required Color color}) {
    return Container(
        width: 260,
        height: 180,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadiusDirectional.circular(20)),
        padding: EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Padding(
              padding: const EdgeInsets.all(40),
              child: quicksandWhiteBold(count, fontSize: 28)),
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
                    future: getAllWindowOrderDocs(windowDoc.id),
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

  Widget _logInContainer() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(ImagePaths.heritageBackground),
              fit: BoxFit.cover)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(ImagePaths.heritageIcon),
                itcBaumansWhiteBold('HERITAGE ALUMINUM SALES CORPORATION',
                    fontSize: 40),
                itcBaumansWhiteBold('• LOS BAÑOS •')
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                border: Border.all(color: CustomColors.lavenderMist),
                borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  vertical20Pix(
                      child: quicksandWhiteBold('iMeasure', fontSize: 40)),
                  CustomTextField(
                      text: 'Email Address',
                      controller: emailController,
                      textInputType: TextInputType.emailAddress,
                      fillColor: CustomColors.deepCharcoal,
                      textColor: Colors.white,
                      displayPrefixIcon: const Icon(Icons.email,
                          color: CustomColors.lavenderMist)),
                  const Gap(16),
                  CustomTextField(
                    text: 'Password',
                    controller: passwordController,
                    textInputType: TextInputType.visiblePassword,
                    fillColor: CustomColors.deepCharcoal,
                    textColor: Colors.white,
                    displayPrefixIcon: const Icon(Icons.lock,
                        color: CustomColors.lavenderMist),
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
              ),
            ),
          )
        ],
      ),
    );
  }
}
