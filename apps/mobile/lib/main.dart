import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/app.dart';

void main() {
  // runZonedGuarded: bắt mọi lỗi async chưa xử lý để app không crash trắng.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Log lỗi widget thay vì để màn đỏ làm crash trải nghiệm.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };

      // Init Firebase có thể fail (mạng/cấu hình) — không để nó chặn app khởi động.
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e, s) {
        debugPrint('Firebase init failed: $e\n$s');
      }

      runApp(const ProviderScope(child: TMovieApp()));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}
