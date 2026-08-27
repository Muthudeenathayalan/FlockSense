import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator();
  }
}
