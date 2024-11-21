// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_field, prefer_final_fields

import 'package:flutter/material.dart';

class Newscreen extends StatefulWidget {
  const Newscreen({super.key});

  @override
  State<Newscreen> createState() => _NewscreenState();
}

class _NewscreenState extends State<Newscreen> {
  List _stories = [
    'Story1',
    'story2',
    'story3',
    'story4',
    'story5',
    'story6',
    'story7',
    'story8'
  ];
  List _posts = ['Post1', 'Post2', 'Post3', 'Post4'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }
}
