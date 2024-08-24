import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:imeasure/providers/loading_provider.dart';

import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_field_widget.dart';
import '../widgets/text_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (hasLoggedInUser()) {
      GoRouter.of(context).goNamed(GoRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
        body: Container(
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
                color: Colors.black.withOpacity(0.4),
                border: Border.all(color: CustomColors.lavenderMist),
                borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  vertical10Pix(
                      child: quicksandWhiteBold('iMeasure', fontSize: 40)),
                  CustomTextField(
                      text: 'Email Address',
                      controller: emailController,
                      textInputType: TextInputType.emailAddress,
                      fillColor: CustomColors.deepCharcoal,
                      textColor: Colors.white,
                      displayPrefixIcon: const Icon(Icons.email,
                          color: CustomColors.lavenderMist)),
                  vertical10Pix(
                    child: CustomTextField(
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
                  ),
                  vertical10Pix(
                      child: CustomTextField(
                          text: 'Confirm Password',
                          controller: confirmPasswordController,
                          textInputType: TextInputType.visiblePassword,
                          fillColor: CustomColors.deepCharcoal,
                          textColor: Colors.white,
                          displayPrefixIcon: const Icon(Icons.lock,
                              color: CustomColors.lavenderMist),
                          onSearchPress: () => logInUser(context, ref,
                              emailController: emailController,
                              passwordController: passwordController))),
                  Divider(color: Colors.white),
                  vertical10Pix(
                      child: CustomTextField(
                    text: 'First Name',
                    controller: firstNameController,
                    textInputType: TextInputType.name,
                    fillColor: CustomColors.deepCharcoal,
                    textColor: Colors.white,
                    displayPrefixIcon: const Icon(Icons.person,
                        color: CustomColors.lavenderMist),
                  )),
                  vertical10Pix(
                      child: CustomTextField(
                    text: 'Last Name',
                    controller: lastNameController,
                    textInputType: TextInputType.name,
                    fillColor: CustomColors.deepCharcoal,
                    textColor: Colors.white,
                    displayPrefixIcon: const Icon(Icons.person,
                        color: CustomColors.lavenderMist),
                  )),
                  Divider(color: Colors.white),
                  vertical10Pix(
                      child: CustomTextField(
                    text: 'Mobile Number',
                    controller: mobileNumberController,
                    textInputType: TextInputType.number,
                    fillColor: CustomColors.deepCharcoal,
                    textColor: Colors.white,
                    displayPrefixIcon: const Icon(Icons.numbers,
                        color: CustomColors.lavenderMist),
                  )),
                  vertical10Pix(
                      child: CustomTextField(
                    text: 'Address',
                    controller: addressController,
                    textInputType: TextInputType.streetAddress,
                    fillColor: CustomColors.deepCharcoal,
                    textColor: Colors.white,
                    displayPrefixIcon: const Icon(Icons.house,
                        color: CustomColors.lavenderMist),
                  )),
                  Divider(color: Colors.white),
                  TextButton(
                      onPressed: () =>
                          GoRouter.of(context).goNamed(GoRoutes.login),
                      child: quicksandWhiteRegular("Already have an account?",
                          decoration: TextDecoration.underline)),
                  submitButton(context,
                      label: 'SIGN UP',
                      onPress: () => registerNewUser(context, ref,
                          emailController: emailController,
                          passwordController: passwordController,
                          confirmPasswordController: confirmPasswordController,
                          firstNameController: firstNameController,
                          lastNameController: lastNameController,
                          mobileNumberController: mobileNumberController,
                          addressController: addressController)),
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }
}
