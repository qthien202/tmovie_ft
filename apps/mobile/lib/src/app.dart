import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/core.dart';
import 'router/app_router.dart';

class TMovieApp extends StatefulWidget {
  const TMovieApp({super.key});

  @override
  State<TMovieApp> createState() => _TMovieAppState();
}

class _TMovieAppState extends State<TMovieApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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
