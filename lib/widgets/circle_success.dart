import 'package:flutter/material.dart';

class CircleSuccess extends StatelessWidget {
  const CircleSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Center(
        child: Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
    );
  }
}
