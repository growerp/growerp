import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class G_DropDownSearch<T> extends StatelessWidget {
  G_DropDownSearch(
      {Key? key,
      required this.controller,
      required this.selectedItem,
      this.title = '',
      this.labelText = '',
      required this.itemAsString,
      required this.asyncItems,
      this.validator,
      this.onChanged})
      : super(key: key);

  final TextEditingController controller;
  final T selectedItem;
  final String title;
  final String labelText;
  final String itemAsString;
  final Future<List<T>> Function(String)? asyncItems;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      key: Key('productDropDown'),
      selectedItem: selectedItem,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          autofocus: true,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
          ),
          controller: controller,
        ),
        menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
        title: Container(
            height: 50,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                )),
            child: Center(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )))),
      ),
      dropdownSearchDecoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
      ),
      showClearButton: false,
      itemAsString: (T? u) => itemAsString,
      asyncItems: asyncItems,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
