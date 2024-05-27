import 'package:flutter/material.dart';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

import 'board.dart';
import 'home.dart';
import 'login.dart';
import 'addProject.dart';
import 'calendar.dart';
import 'profile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamSync',
      initialRoute: '/splash',
      routes: {
        '/splash': (BuildContext context) => const SplashScreen(),
        '/login': (BuildContext context) => const LoginPage(),
        '/': (BuildContext context) => const HomePage(),
        '/profile': (BuildContext context) => ProfilePage(),
        '/addProject': (BuildContext context) => AddProjectPage(),
        '/calendar': (BuildContext context) => const CalendarPage(),
        '/board': (BuildContext context) => BoardPage(),
      },
      theme: ThemeData.light(
        useMaterial3: true,
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        Navigator.of(context).pushReplacement(_createRoute());
      });
    });

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
                child: Text(
          'TeamSync',
          style: GoogleFonts.jomhuria(
            fontSize: 90,
            color: Color(0xFFF46A6A),
            fontWeight: FontWeight.w500,
          ),
        ))));
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      final tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}
