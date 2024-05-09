import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/screens/add_window_screen.dart';
import 'package:imeasure/screens/edit_window_screen.dart';
import 'package:imeasure/screens/view_generated_order_screen.dart';
import 'package:imeasure/screens/view_orders_screen.dart';
import 'package:imeasure/screens/view_selected_user_screen.dart';
import 'package:imeasure/screens/view_transactions_screen.dart';
import 'package:imeasure/screens/view_users_screen.dart';
import 'package:imeasure/screens/view_windows_screen.dart';

import '../screens/add_faq_screen.dart';
import '../screens/edit_faq_screen.dart';
import '../screens/home_screen.dart';
import '../screens/view_faqs_screen.dart';
import '../screens/view_selected_window_screen.dart';
import 'string_util.dart';

class GoRoutes {
  static const home = '/';
  static const users = 'users';
  static const selectedUser = 'selectedUser';
  static const windows = 'windows';
  static const addWindow = 'addWindow';
  static const editWindow = 'editWindow';
  static const selectedWindow = 'selectedWindow';
  static const transactions = 'transactions';
  static const orders = 'orders';
  static const generatedOrder = 'generatedOrder';
  static const viewFAQs = 'viewFAQs';
  static const addFAQ = 'addFAQ';
  static const editFAQ = 'editFAQ';
}

final GoRouter goRoutes = GoRouter(initialLocation: GoRoutes.home, routes: [
  GoRoute(
      name: GoRoutes.home,
      path: GoRoutes.home,
      pageBuilder: (context, state) =>
          customTransition(context, state, const HomeScreen()),
      routes: [
        GoRoute(
            name: GoRoutes.users,
            path: GoRoutes.users,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewUsersScreen())),
        GoRoute(
            name: GoRoutes.selectedUser,
            path: '${GoRoutes.users}/:${PathParameters.userID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedUserScreen(
                    userID: state.pathParameters[PathParameters.userID]!))),
        GoRoute(
            name: GoRoutes.windows,
            path: GoRoutes.windows,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewWindowsScreen())),
        GoRoute(
            name: GoRoutes.addWindow,
            path: '${GoRoutes.windows}/add',
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddWindowScreen())),
        GoRoute(
            name: GoRoutes.editWindow,
            path: '${GoRoutes.windows}/:${PathParameters.windowID}/edit',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditWindowScreen(
                    windowID: state.pathParameters[PathParameters.windowID]!))),
        GoRoute(
            name: GoRoutes.selectedWindow,
            path: '${GoRoutes.windows}/:${PathParameters.windowID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedWindowScreen(
                    windowID: state.pathParameters[PathParameters.windowID]!))),
        GoRoute(
            name: GoRoutes.transactions,
            path: GoRoutes.transactions,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewTransactionsScreen())),
        GoRoute(
            name: GoRoutes.orders,
            path: GoRoutes.orders,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewOrdersScreen())),
        GoRoute(
            name: GoRoutes.generatedOrder,
            path: '${GoRoutes.orders}/:${PathParameters.orderID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewGeneratedOrderScreen(
                    orderID: state.pathParameters[PathParameters.orderID]!))),
        //  FAQs
        GoRoute(
            name: GoRoutes.viewFAQs,
            path: GoRoutes.viewFAQs,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewFAQsScreen())),
        GoRoute(
            name: GoRoutes.addFAQ,
            path: GoRoutes.addFAQ,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddFAQScreen())),
        GoRoute(
            name: GoRoutes.editFAQ,
            path: '${GoRoutes.editFAQ}/:${PathParameters.faqID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditFAQScreen(
                    faqID: state.pathParameters[PathParameters.faqID]!))),
      ])
]);

CustomTransitionPage customTransition(
    BuildContext context, GoRouterState state, Widget widget) {
  return CustomTransitionPage(
      fullscreenDialog: true,
      key: state.pageKey,
      child: widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return easeInOutCircTransition(animation, child);
      });
}

FadeTransition easeInOutCircTransition(
    Animation<double> animation, Widget child) {
  return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child);
}
