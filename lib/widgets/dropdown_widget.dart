import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

Widget dropdownWidget(
    String selectedOption,
    Function(String?) onDropdownValueChanged,
    List<String> dropdownItems,
    String label,
    bool searchable) {
  return DropdownSearch<String>(
    popupProps: PopupProps.menu(
        fit: FlexFit.loose,
        showSelectedItems: true,
        showSearchBox: searchable,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Select your ${label.toLowerCase()}',
              labelStyle: TextStyle(
                color: Colors.black.withOpacity(0.4),
              ),
              filled: true,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black, width: 1)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10)),
        )),
    items: dropdownItems,
    onChanged: onDropdownValueChanged,
    selectedItem: label,
  );
}
