import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'router/app_router.dart';

class TvApp extends StatelessWidget {
  const TvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TMovie TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: tvRouter,
    );
  }
}
