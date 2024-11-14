import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/custom_padding_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        firstNameController.text = userData[UserFields.firstName];
        lastNameController.text = userData[UserFields.lastName];
        addressController.text = userData[UserFields.address];
        mobileNumberController.text = userData[UserFields.mobileNumber];
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting user profile: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.profile),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Container(
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                  child:
                      Column(children: [_backButtons(), _accountFields()])))),
    );
  }

  Widget _backButtons() {
    return all20Pix(
        child: Row(
      children: [
        backButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.profile))
      ],
    ));
  }

  Widget _accountFields() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          border: Border.all(color: CustomColors.lavenderMist),
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            vertical10Pix(
                child: quicksandWhiteBold('EDIT PROFILE', fontSize: 40)),
            vertical10Pix(
                child: CustomTextField(
              text: 'First Name',
              controller: firstNameController,
              textInputType: TextInputType.name,
              displayPrefixIcon:
                  const Icon(Icons.person, color: CustomColors.deepCharcoal),
            )),
            vertical10Pix(
                child: CustomTextField(
              text: 'Last Name',
              controller: lastNameController,
              textInputType: TextInputType.name,
              displayPrefixIcon:
                  const Icon(Icons.person, color: CustomColors.deepCharcoal),
            )),
            Divider(color: Colors.white),
            vertical10Pix(
                child: CustomTextField(
              text: 'Mobile Number',
              controller: mobileNumberController,
              textInputType: TextInputType.number,
              displayPrefixIcon:
                  const Icon(Icons.numbers, color: CustomColors.deepCharcoal),
            )),
            vertical10Pix(
                child: CustomTextField(
              text: 'Address',
              controller: addressController,
              textInputType: TextInputType.streetAddress,
              displayPrefixIcon:
                  const Icon(Icons.house, color: CustomColors.deepCharcoal),
            )),
            vertical10Pix(
                child: CustomTextField(
              text: 'Email Address',
              controller: emailController,
              textInputType: TextInputType.emailAddress,
              displayPrefixIcon:
                  const Icon(Icons.email, color: CustomColors.deepCharcoal),
            )),
            Divider(color: Colors.white),
            submitButton(context,
                label: 'EDIT PROFILE',
                onPress: () => editUserProfile(context, ref,
                    firstNameController: firstNameController,
                    lastNameController: lastNameController,
                    addressController: addressController,
                    mobileNumberController: mobileNumberController,
                    emailAddressController: emailController)),
          ],
        ),
      ),
    );
  }
}
