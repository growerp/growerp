import 'package:flutter/material.dart';

class BinaryRadioButton extends StatefulWidget {
  final bool? isDebit;
  final bool canUpdate;
  final Function(bool?) onValueChanged;

  const BinaryRadioButton(
      {super.key,
      required this.onValueChanged,
      required this.isDebit,
      this.canUpdate = true});

  @override
  BinaryRadioButtonState createState() => BinaryRadioButtonState();
}

class BinaryRadioButtonState extends State<BinaryRadioButton> {
  bool? _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isDebit;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Debit'),
        Radio(
          value: true,
          groupValue: _isSelected,
          onChanged: widget.canUpdate
              ? (value) {
                  setState(() {
                    _isSelected = (value ?? false) as bool?;
                  });
                }
              : null,
        ),
        Radio(
          value: false,
          groupValue: _isSelected,
          onChanged: widget.canUpdate
              ? (value) {
                  setState(() {
                    _isSelected = (value ?? false) as bool?;
                  });
                }
              : null,
        ),
        const Text('Credit'),
      ],
    );
  }

  void onValueChanged(bool newValue) {
    setState(() {
      _isSelected = newValue;
    });

    widget.onValueChanged(_isSelected);
  }
}
