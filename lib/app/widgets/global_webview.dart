import 'package:get/get.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:retrofit/retrofit.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GlobalWebview extends StatelessWidget {
  final String? tittleWeb;
  final String? linkWeb;
  final bool? intoOrder;
  const GlobalWebview({Key? key, this.tittleWeb, this.linkWeb, this.intoOrder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        body: WebView(
          initialUrl: linkWeb ?? "",
          allowsInlineMediaPlayback: true,
          // initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
          javascriptMode: JavascriptMode.unrestricted,
          initialMediaPlaybackPolicy:
              AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
        ));
  }
}
