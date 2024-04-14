import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/widgets/text_widgets.dart';

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
        /*final owners = await getAllOwnerDocs();
        ownersCount = owners.length;
        final vehicles = await getAllVehicleDocs();
        vehiclesCount = vehicles.length;*/
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
                        //_platformSummary(),
                        _analyticsBreakdown(),
                        //Row(children: [_paymentStatuses()])
                      ],
                    )),
              )),
        )
      ],
    );
  }

  Widget _platformSummary() {
    String topRatedName = '';
    String bestSellerName = '';

    return vertical20Pix(
      child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: CustomColors.slateBlue,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            montserratWhiteBold('OVERALL TOTAL SALES: PHP 000', fontSize: 30),
            montserratWhiteBold(
                'Best Selling Product: ${bestSellerName.isNotEmpty ? bestSellerName : 'N/A'}',
                fontSize: 18),
            montserratWhiteBold(
                'Best Selling Service: ${topRatedName.isNotEmpty ? topRatedName : 'N/A'}',
                fontSize: 18)
          ])),
    );
  }

  Widget _analyticsBreakdown() {
    return vertical20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CustomColors.powderBlue,
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
                displayIcon: const Icon(Icons.people),
                onPress: () => GoRouter.of(context).goNamed(GoRoutes.windows)),
            analyticReportWidget(context,
                count: ordersCount.toString(),
                demographic: 'Orders',
                displayIcon: const Icon(Icons.people),
                onPress: () => GoRouter.of(context).goNamed(GoRoutes.orders)),
          ],
        ),
      ),
    );
  }

  /*Widget _paymentStatuses() {
    return breakdownContainer(context,
        child: Column(
          children: [
            montserratBlackBold('PAYMENT STATUSES'),
            PieChart(
                dataMap: paymentBreakdown,
                colorList: [
                  CustomColors.grenadine,
                  CustomColors.ultimateGray,
                  CustomColors.blackBeauty
                ],
                chartValuesOptions: ChartValuesOptions(decimalPlaces: 0)),
          ],
        ));
  }*/

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
