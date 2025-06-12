import 'package:flutter/material.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        backgroundColor: const Color(0xFF3730A3),
      ),
      body: const Center(
        child: Text('Your timeline content goes here'),
      ),
    );
  }
}