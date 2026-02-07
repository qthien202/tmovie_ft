import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'router/app_router.dart';

class TMovieApp extends StatelessWidget {
  const TMovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TMOVIE',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
