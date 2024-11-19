import 'package:flutter/material.dart';

class Previousmonthstatusbuilder extends StatefulWidget {
  const Previousmonthstatusbuilder({super.key});

  @override
  State<Previousmonthstatusbuilder> createState() =>
      _PreviousmonthstatusbuilderState();
}

class _PreviousmonthstatusbuilderState
    extends State<Previousmonthstatusbuilder> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          width: 330,
          child: const Center(child: Text('previous month screen')),
        ),
      ],
    );
  }
}
