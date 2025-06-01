import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:radius/pages/select_avatar.dart';
import 'package:radius/pages/welcome.dart';
import 'firebase_options.dart';
import 'package:radius/pages/map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MapPage();
  }
}
