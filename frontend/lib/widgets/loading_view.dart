import 'package:flutter/material.dart';

/// Shown while data is being loaded from the backend.
class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}