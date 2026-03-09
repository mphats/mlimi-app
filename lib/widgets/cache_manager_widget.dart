import 'package:flutter/material.dart';

class CacheManagerWidget extends StatefulWidget {
  final Widget child;

  const CacheManagerWidget({super.key, required this.child});

  @override
  State<CacheManagerWidget> createState() => _CacheManagerWidgetState();
}

class _CacheManagerWidgetState extends State<CacheManagerWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
