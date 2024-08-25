import 'dart:io';

import 'package:flutter/material.dart';
import 'package:five_flight/pages/home.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.bottom]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;

  runApp(const FiveFlight());
}

class FiveFlight extends StatelessWidget {
  const FiveFlight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiveFlight Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        // scaffoldBackgroundColor: const Color.fromARGB(255, 17, 17, 25),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
