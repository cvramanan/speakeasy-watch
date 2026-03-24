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
