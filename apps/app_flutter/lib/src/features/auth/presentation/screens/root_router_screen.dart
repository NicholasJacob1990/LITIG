import 'package:flutter/material.dart';

class RootRouterScreen extends StatelessWidget {
  const RootRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 