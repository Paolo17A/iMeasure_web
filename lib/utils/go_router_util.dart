import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/screens/about_screen.dart';
import 'package:imeasure/screens/add_door_screen.dart';
import 'package:imeasure/screens/add_portfolio_screen.dart';
import 'package:imeasure/screens/add_raw_material_screen.dart';
import 'package:imeasure/screens/add_service_screen.dart';
import 'package:imeasure/screens/add_testimonial_screen.dart';
import 'package:imeasure/screens/add_window_screen.dart';
import 'package:imeasure/screens/appointment_history_screen.dart';
import 'package:imeasure/screens/cart_screen.dart';
import 'package:imeasure/screens/completed_orders_screen.dart';
import 'package:imeasure/screens/edit_door_screen.dart';
import 'package:imeasure/screens/edit_portfolio_screen.dart';
import 'package:imeasure/screens/edit_profile_screen.dart';
import 'package:imeasure/screens/edit_raw_material_screen.dart';
import 'package:imeasure/screens/edit_testimonial_screen.dart';
import 'package:imeasure/screens/edit_window_screen.dart';
import 'package:imeasure/screens/forgot_password_screen.dart';
import 'package:imeasure/screens/help_screen.dart';
import 'package:imeasure/screens/history_screen.dart';
import 'package:imeasure/screens/items_screen.dart';
import 'package:imeasure/screens/login_screen.dart';
import 'package:imeasure/screens/order_history_screen.dart';
import 'package:imeasure/screens/profile_screen.dart';
import 'package:imeasure/screens/register_screen.dart';
import 'package:imeasure/screens/search_result_screen.dart';
import 'package:imeasure/screens/shop_screen.dart';
import 'package:imeasure/screens/transaction_history_screen.dart';
import 'package:imeasure/screens/view_appointments_screen.dart';
import 'package:imeasure/screens/view_doors_screen.dart';
import 'package:imeasure/screens/view_gallery_screen.dart';
import 'package:imeasure/screens/view_generated_order_screen.dart';
import 'package:imeasure/screens/view_orders_screen.dart';
import 'package:imeasure/screens/view_pending_delivery_screen.dart';
import 'package:imeasure/screens/view_pending_labor_screen.dart';
import 'package:imeasure/screens/view_portfolio_screen.dart';
import 'package:imeasure/screens/view_raw_materials_screen.dart';
import 'package:imeasure/screens/view_selected_door_screen.dart';
import 'package:imeasure/screens/view_selected_raw_material_screen.dart';
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
  static const register = 'register';
  static const forgotPassword = 'forgotPassword';
  //  GUEST
  static const about = 'about';
  static const items = 'items';
  static const shop = 'shop';
  //  USER
  static const cart = 'cart';
  static const profile = 'profile';
  static const editProfile = 'editProfile';
  static const orderHistory = 'orderHistory';
  static const search = 'search';
  static const transactionHistory = 'transactionHistory';
  static const appointmentHistory = 'appointmentHistory';
  //  ADMIN
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
  static const pendingLabor = 'pendingLabor';
  static const pendingDelivery = 'pendingDelivery';
  static const help = 'help';
  static const history = 'history';
  static const completedOrders = 'completedOrders';
  static const viewAppointments = 'viewAppointments';
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
            name: GoRoutes.register,
            path: GoRoutes.register,
            pageBuilder: (context, state) =>
                customTransition(context, state, const RegisterScreen())),
        GoRoute(
            name: GoRoutes.forgotPassword,
            path: GoRoutes.forgotPassword,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ForgotPasswordScreen())),
        GoRoute(
            name: GoRoutes.about,
            path: GoRoutes.about,
            pageBuilder: (context, state) =>
                customTransition(context, state, const AboutScreen())),
        GoRoute(
            name: GoRoutes.items,
            path: GoRoutes.items,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ItemsScreen())),
        GoRoute(
            name: GoRoutes.shop,
            path: GoRoutes.shop,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ShopScreen())),
        GoRoute(
            name: GoRoutes.cart,
            path: GoRoutes.cart,
            pageBuilder: (context, state) =>
                customTransition(context, state, const CartScreen())),
        GoRoute(
            name: GoRoutes.profile,
            path: GoRoutes.profile,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ProfileScreen())),
        GoRoute(
            name: GoRoutes.editProfile,
            path: GoRoutes.editProfile,
            pageBuilder: (context, state) =>
                customTransition(context, state, const EditProfileScreen())),
        GoRoute(
            name: GoRoutes.orderHistory,
            path: GoRoutes.orderHistory,
            pageBuilder: (context, state) =>
                customTransition(context, state, const OrderHistoryScreen())),
        GoRoute(
            name: GoRoutes.search,
            path: '${GoRoutes.search}/:${PathParameters.searchInput}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                SearchResultScreen(
                    searchInput:
                        state.pathParameters[PathParameters.searchInput]!))),
        GoRoute(
            name: GoRoutes.transactionHistory,
            path: GoRoutes.transactionHistory,
            pageBuilder: (context, state) => customTransition(
                context, state, const TransactionHistoryScreen())),
        GoRoute(
            name: GoRoutes.appointmentHistory,
            path: GoRoutes.appointmentHistory,
            pageBuilder: (context, state) => customTransition(
                context, state, const AppointmentHistoryScreen())),
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
            name: GoRoutes.selectedRawMaterial,
            path: '${GoRoutes.rawMaterial}/:${PathParameters.itemID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedRawMaterialScreen(
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
        GoRoute(
            name: GoRoutes.pendingLabor,
            path: GoRoutes.pendingLabor,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewPendingLaborScreen())),
        GoRoute(
            name: GoRoutes.pendingDelivery,
            path: GoRoutes.pendingDelivery,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewPendingDeliveryScreen())),
        GoRoute(
            name: GoRoutes.help,
            path: GoRoutes.help,
            pageBuilder: (context, state) =>
                customTransition(context, state, const HelpScreen())),
        GoRoute(
            name: GoRoutes.history,
            path: GoRoutes.history,
            pageBuilder: (context, state) =>
                customTransition(context, state, const HistoryScreen())),
        GoRoute(
            name: GoRoutes.completedOrders,
            path: GoRoutes.completedOrders,
            pageBuilder: (context, state) => customTransition(
                context, state, const CompletedOrdersScreen())),
        GoRoute(
            name: GoRoutes.viewAppointments,
            path: GoRoutes.viewAppointments,
            pageBuilder: (context, state) => customTransition(
                context, state, const ViewAppointmentsScreen())),
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
