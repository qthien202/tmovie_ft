import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'shared/desktop_design_system.dart';

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TMovie',
      debugShowCheckedModeBanner: false,
      theme: DS.darkTheme,
      routerConfig: desktopRouter,
    );
  }
}
