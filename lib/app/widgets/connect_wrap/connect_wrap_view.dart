import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'connect_wrap_logic.dart';

class ConnectWrapView extends StatelessWidget {
  final Widget child;
  const ConnectWrapView({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(ConnectWrapLogic());

    return child;
  }
}
