import 'dart:io';
import 'package:flutter/material.dart';

class WatchScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const WatchScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    // iOS: full-screen layout with SafeArea and comfortable sizing
    if (Platform.isIOS) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: child,
          ),
        ),
      );
    }

    // Android (Wear OS): round screen with ClipOval
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipOval(
        child: SizedBox.expand(
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
