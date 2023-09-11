import 'package:flutter/material.dart';

class CreditDebitButton extends StatefulWidget {
  final bool? isDebit;
  final bool canUpdate;
  final Function(bool?) onValueChanged;

  const CreditDebitButton(
      {super.key,
      required this.onValueChanged,
      required this.isDebit,
      this.canUpdate = true});

  @override
  CreditDebitButtonState createState() => CreditDebitButtonState();
}

class CreditDebitButtonState extends State<CreditDebitButton> {
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
                  onValueChanged((value ?? false) as bool);
                }
              : null,
        ),
        Radio(
          value: false,
          groupValue: _isSelected,
          onChanged: widget.canUpdate
              ? (value) {
                  onValueChanged((value ?? false) as bool);
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
