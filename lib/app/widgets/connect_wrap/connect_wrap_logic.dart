import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectWrapLogic extends GetxController {
  Connectivity? connectivity;
  @override
  void onReady() async {
    super.onReady();
    connectivity ??= Connectivity();
    connectivity?.onConnectivityChanged.listen((event) {
      bool isConnected = this.isConnected(connectivityResult: event);
      if (!isConnected) {
        showWarningConnect();
      }
    });
    final event = await connectivity?.checkConnectivity();
    bool isConnected = this.isConnected(connectivityResult: event);
    if (!isConnected) {
      showWarningConnect();
    }
  }

  bool isConnected({ConnectivityResult? connectivityResult}) {
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> showWarningConnect() async {
    SnackbarController? snackBar;
    snackBar = Get.showSnackbar(GetSnackBar(
      title: "Thông báo",
      message: "Không có kết nối internet",
      mainButton: ElevatedButton(
        onPressed: () => snackBar?.close(),
        child: Text("Đóng"),
      ),
    ));
  }
}
