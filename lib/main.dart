// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';      // ✅ 추가
import 'firebase_options.dart';                        // ✅ 추가 (flutterfire configure가 만들어 준 파일)

import 'core/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {                            // ✅ async 로 변경
  WidgetsFlutterBinding.ensureInitialized();           // ✅ Flutter 바인딩 초기화

  await Firebase.initializeApp(                        // ✅ Firebase 초기화
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // debugProfileBuildsEnabled = true;
  // debugPrintRebuildDirtyWidgets = true;

  runApp(const MyApp());
}
// 123123

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Search',
      theme: appTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
