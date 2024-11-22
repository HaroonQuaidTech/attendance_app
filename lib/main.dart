import 'package:flutter/material.dart';
import 'package:quaidtech/screens/Checkin.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/login.dart';
import 'package:quaidtech/screens/adminhome.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:quaidtech/screens/profile.dart';
import 'package:quaidtech/screens/signup.dart';
import 'package:quaidtech/screens/splashscreen.dart';
import 'package:quaidtech/screens/stastics.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            surface: Color(0xffFFFFFF),
            primary: Color(0xffFF6100),
            secondary: Color(0xff3B3A3C),
            tertiary: Color(0xffEFEFEF),
            inversePrimary: Color(0xffFFE9DC),
          ),
          fontFamily: 'Kumbh Sans',
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xffFF6100),
          ),
        ),
        initialRoute: 'splash',
        routes: {
          'login': (context) => const LoginScreen(),
          'signup': (context) => const SignUpScreen(),
          'home': (context) => const HomeScreen(),
          'checkin': (context) => const CheckinScreen(),
          'notification': (context) => const NotificationScreen(),
          'profile': (context) => const ProfileScreen(),
          'stat': (context) => const StatsticsScreen(),
          'adminh': (context) => const AdminHomeScreen(),
          'splash': (context) => const Splashscreen(),
        },  
      ),
    );
  }
}

class CustomTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        surface: Color(0xff22AF41),
        primary: Color(0xffF6C15B),
        secondary: Color(0xffEC5851),
        tertiary: Color(0xffF07E25),
        inversePrimary: Color(0xff8E71DF),
        secondaryFixed: Colors.blueGrey,
      ),
    );
  }
}
