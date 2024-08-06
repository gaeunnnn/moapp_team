import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'projectDetail.dart';
import 'board.dart';
import 'home.dart';
import 'login.dart';
import 'addProject.dart';
import 'calendar.dart';
import 'signup.dart';
import 'profile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamSync',
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(
                builder: (context) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignupPage());
          case '/':
            return MaterialPageRoute(builder: (context) => const HomePage());
          case '/addProject':
            return MaterialPageRoute(builder: (context) => AddProjectPage());
          case '/detail':
            final projectId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProjectDetailPage(projectId: projectId),
            );
          case '/calendar':
            final projectId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => CalendarPage(projectId: projectId),
            );
          case '/board':
            final projectId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => BoardPage(projectId: projectId),
            );
          case '/profile':
            return MaterialPageRoute(builder: (context) => ProfilePage());
          default:
            return null;
        }
      },
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
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
