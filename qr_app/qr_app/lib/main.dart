import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_app/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Scan, Create & Share QR",
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.light,
            seedColor: Color.fromARGB(255, 253, 122, 0)),
      ),
      home: HomeScreen(),
    );
  }
}
