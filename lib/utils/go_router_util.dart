import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/screens/add_door_screen.dart';
import 'package:imeasure/screens/add_portfolio_screen.dart';
import 'package:imeasure/screens/add_raw_material_screen.dart';
import 'package:imeasure/screens/add_service_screen.dart';
import 'package:imeasure/screens/add_testimonial_screen.dart';
import 'package:imeasure/screens/add_window_screen.dart';
import 'package:imeasure/screens/edit_door_screen.dart';
import 'package:imeasure/screens/edit_portfolio_screen.dart';
import 'package:imeasure/screens/edit_raw_material_screen.dart';
import 'package:imeasure/screens/edit_testimonial_screen.dart';
import 'package:imeasure/screens/edit_window_screen.dart';
import 'package:imeasure/screens/login_screen.dart';
import 'package:imeasure/screens/view_doors_screen.dart';
import 'package:imeasure/screens/view_gallery_screen.dart';
import 'package:imeasure/screens/view_generated_order_screen.dart';
import 'package:imeasure/screens/view_orders_screen.dart';
import 'package:imeasure/screens/view_portfolio_screen.dart';
import 'package:imeasure/screens/view_raw_materials_screen.dart';
import 'package:imeasure/screens/view_selected_door_screen.dart';
import 'package:imeasure/screens/view_selected_user_screen.dart';
import 'package:imeasure/screens/view_services_screen.dart';
import 'package:imeasure/screens/view_testimonials_screen.dart';
import 'package:imeasure/screens/view_transactions_screen.dart';
import 'package:imeasure/screens/view_users_screen.dart';
import 'package:imeasure/screens/view_windows_screen.dart';

import '../screens/add_faq_screen.dart';
import '../screens/edit_faq_screen.dart';
import '../screens/edit_service_screen.dart';
import '../screens/home_screen.dart';
import '../screens/view_faqs_screen.dart';
import '../screens/view_selected_window_screen.dart';
import 'string_util.dart';

class GoRoutes {
  static const home = '/';
  static const login = 'login';
  static const users = 'users';
  static const selectedUser = 'selectedUser';
  static const windows = 'windows';
  static const addWindow = 'addWindow';
  static const editWindow = 'editWindow';
  static const selectedWindow = 'selectedWindow';
  static const doors = 'doors';
  static const addDoor = 'addDoor';
  static const editDoor = 'editDoor';
  static const transactions = 'transactions';
  static const selectedDoor = 'selectedDoor';
  static const rawMaterial = 'rawMaterial';
  static const addRawMaterial = 'addRawMaterial';
  static const editRawMaterial = 'editRawMaterial';
  static const selectedRawMaterial = 'selectedRawMaterial';
  static const orders = 'orders';
  static const generatedOrder = 'generatedOrder';
  static const viewFAQs = 'viewFAQs';
  static const addFAQ = 'addFAQ';
  static const editFAQ = 'editFAQ';
  static const gallery = 'gallery';
  static const services = 'services';
  static const addService = 'addService';
  static const editService = 'editService';
  static const testimonials = 'testimonials';
  static const addTestimonial = 'addTestimonial';
  static const editTestimonial = 'editTestimonial';
  static const portfolio = 'portfolio';
  static const addPortfolio = 'addPortfolio';
  static const editPortfolio = 'editPortfolio';
}

final GoRouter goRoutes = GoRouter(initialLocation: GoRoutes.home, routes: [
  GoRoute(
      name: GoRoutes.home,
      path: GoRoutes.home,
      pageBuilder: (context, state) =>
          customTransition(context, state, const HomeScreen()),
      routes: [
        GoRoute(
            name: GoRoutes.login,
            path: GoRoutes.login,
            pageBuilder: (context, state) =>
                customTransition(context, state, const LoginScreen())),
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
            path: '${GoRoutes.windows}/:${PathParameters.itemID}/edit',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditWindowScreen(
                    itemID: state.pathParameters[PathParameters.itemID]!))),
        GoRoute(
            name: GoRoutes.selectedWindow,
            path: '${GoRoutes.windows}/:${PathParameters.itemID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedWindowScreen(
                    itemID: state.pathParameters[PathParameters.itemID]!))),
        GoRoute(
            name: GoRoutes.doors,
            path: GoRoutes.doors,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewDoorsScreen())),
        GoRoute(
            name: GoRoutes.addDoor,
            path: '${GoRoutes.doors}/add',
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddDoorScreen())),
        GoRoute(
            name: GoRoutes.editDoor,
            path: '${GoRoutes.doors}/:${PathParameters.itemID}/edit',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditDoorScreen(
                    itemID: state.pathParameters[PathParameters.itemID]!))),
        GoRoute(
            name: GoRoutes.selectedDoor,
            path: '${GoRoutes.doors}/:${PathParameters.itemID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedDoorScreen(
                    itemID: state.pathParameters[PathParameters.itemID]!))),
        GoRoute(
            name: GoRoutes.rawMaterial,
            path: GoRoutes.rawMaterial,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewRawMaterialsScreen())),
        GoRoute(
            name: GoRoutes.addRawMaterial,
            path: '${GoRoutes.rawMaterial}/add',
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddRawMaterialScreen())),
        GoRoute(
            name: GoRoutes.editRawMaterial,
            path: '${GoRoutes.rawMaterial}/:${PathParameters.itemID}/edit',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditRawMaterialScreen(
                    itemID: state.pathParameters[PathParameters.itemID]!))),
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
        //  GALLERY
        GoRoute(
            name: GoRoutes.gallery,
            path: GoRoutes.gallery,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewGalleryScreen())),
        GoRoute(
            name: GoRoutes.services,
            path: GoRoutes.services,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewServicesScreen())),
        GoRoute(
            name: GoRoutes.addService,
            path: GoRoutes.addService,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddServiceScreen())),
        GoRoute(
            name: GoRoutes.editService,
            path: '${GoRoutes.editService}/:${PathParameters.galleryID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditServiceScreen(
                    galleryID:
                        state.pathParameters[PathParameters.galleryID]!))),
        GoRoute(
            name: GoRoutes.testimonials,
            path: GoRoutes.testimonials,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewTestimonialsScreen())),
        GoRoute(
            name: GoRoutes.addTestimonial,
            path: GoRoutes.addTestimonial,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddTestimonialScreen())),
        GoRoute(
            name: GoRoutes.editTestimonial,
            path: '${GoRoutes.editTestimonial}/:${PathParameters.galleryID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditTestimonialScreen(
                    galleryID:
                        state.pathParameters[PathParameters.galleryID]!))),
        GoRoute(
            name: GoRoutes.portfolio,
            path: GoRoutes.portfolio,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewPortfolioScreen())),
        GoRoute(
            name: GoRoutes.addPortfolio,
            path: GoRoutes.addPortfolio,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddPortfolioScreen())),
        GoRoute(
            name: GoRoutes.editPortfolio,
            path: '${GoRoutes.editPortfolio}/:${PathParameters.galleryID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditPortfolioScreen(
                    galleryID:
                        state.pathParameters[PathParameters.galleryID]!))),
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
