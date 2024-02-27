
import 'package:flutter/material.dart';

import 'package:get/get.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';


class GlobalWebview extends StatelessWidget {
  final String? tittleWeb;
  final String? linkWeb;
  final bool? intoOrder;
  const GlobalWebview({Key? key, this.tittleWeb, this.linkWeb, this.intoOrder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //  WebViewController controller = WebViewController()
    //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //     ..setBackgroundColor(const Color(0x00000000))
    //     ..setNavigationDelegate(
    //       NavigationDelegate(
    //         onProgress: (int progress) {
    //           // Update loading bar.

    //         },
    //         onPageStarted: (String url) {

    //         },
    //         onPageFinished: (String url) {
    //           print(">>>>>>>>>>>aaaa");
    //         },
    //         onWebResourceError: (WebResourceError error) async {

    //       //    if(intoOrder==true){
    //       //      final logicCart = Get.put(CartLogic());
    //       //     final logicOrder = Get.put(OrderHistoryLogic());
    //       //   logicCart.onReady();
    //       //   Get.back();
    //       //   logicOrder.getOrder();
    //       //    Get.to(const OrderHistoryPage());
    //       // //    Fluttertoast.showToast(msg: "Thanh toán thành công",
    //       // //     backgroundColor: Colors.green
    //       // // );
    //       //    }
    //         },

    //       ),
    //     )
    //     ..loadRequest(Uri.parse(linkWeb??""));
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            tittleWeb ?? '',
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              Get.back();
            },
          ),
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.tryParse(linkWeb.toString())),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                cacheEnabled: true,
                supportZoom: false,
                allowFileAccessFromFileURLs: true,
                useOnLoadResource: true,
                mediaPlaybackRequiresUserGesture: true),
          ),
          onLoadStop: (InAppWebViewController controller, Uri? url) async {},
          onLoadHttpError: (controller, url, statusCode, description) {
           
          },
          
         
        ));
  }
}