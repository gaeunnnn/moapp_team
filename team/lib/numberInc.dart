import 'package:flutter/material.dart';

class NumberInputWithIncrementDecrement extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final Function(int) onChanged;

  NumberInputWithIncrementDecrement({
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  _NumberInputWithIncrementDecrementState createState() =>
      _NumberInputWithIncrementDecrementState();
}

class _NumberInputWithIncrementDecrementState
    extends State<NumberInputWithIncrementDecrement> {
  late int currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  void _increment() {
    setState(() {
      if (currentValue < widget.maxValue) {
        currentValue++;
        widget.onChanged(currentValue);
      }
    });
  }

  void _decrement() {
    setState(() {
      if (currentValue > widget.minValue) {
        currentValue--;
        widget.onChanged(currentValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: _decrement,
        ),
        Text(
          '$currentValue',
          style: TextStyle(fontSize: 18.0),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: _increment,
        ),
      ],
    );
  }
}
