import 'package:flutter/material.dart';

import '../utils/color_util.dart';

class CustomTextField extends StatefulWidget {
  final String text;
  final TextEditingController controller;
  final TextInputType textInputType;
  final Icon? displayPrefixIcon;
  final bool enabled;
  final bool hasSearchButton;
  final Function? onSearchPress;
  final Color? fillColor;
  final double? height;
  const CustomTextField(
      {super.key,
      required this.text,
      required this.controller,
      required this.textInputType,
      this.displayPrefixIcon,
      this.enabled = true,
      this.hasSearchButton = false,
      this.onSearchPress,
      this.height,
      this.fillColor});

  @override
  State<CustomTextField> createState() => _LiliwECommerceTextFieldState();
}

class _LiliwECommerceTextFieldState extends State<CustomTextField> {
  late bool isObscured;

  @override
  void initState() {
    super.initState();
    isObscured = widget.textInputType == TextInputType.visiblePassword;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: TextField(
          enabled: widget.enabled,
          controller: widget.controller,
          obscureText: isObscured,
          cursorColor: CustomColors.deepNavyBlue,
          onSubmitted: (value) {
            if (widget.onSearchPress != null &&
                widget.controller.text.isNotEmpty) {
              widget.onSearchPress!();
            }
          },
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: widget.text,
              labelStyle: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontStyle: FontStyle.italic),
              filled: true,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              fillColor: widget.fillColor ?? Colors.white.withOpacity(0.4),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.white, width: 3.0)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              prefixIcon: widget.displayPrefixIcon,
              suffixIcon: widget.textInputType == TextInputType.visiblePassword
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          isObscured = !isObscured;
                        });
                      },
                      icon: Icon(
                        isObscured ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black.withOpacity(0.6),
                      ))
                  : widget.hasSearchButton && widget.onSearchPress != null
                      ? Transform.scale(
                          scale: 0.95,
                          child: ElevatedButton(
                              onPressed: () {
                                if (widget.controller.text.isEmpty) return;
                                widget.onSearchPress!();
                              },
                              child: const Icon(Icons.search,
                                  color: Colors.white)),
                        )
                      : null),
          keyboardType: widget.textInputType,
          maxLines: widget.textInputType == TextInputType.multiline ? 4 : 1),
    );
  }
}
