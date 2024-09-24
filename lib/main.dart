

// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:quaidtech/screens/Checkin.dart';
import 'package:quaidtech/screens/checkout.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/login.dart';
import 'package:quaidtech/screens/adminhome.dart';
import 'package:quaidtech/screens/newscreen.dart';

import 'package:quaidtech/screens/notification.dart';
import 'package:quaidtech/screens/profile.dart';
import 'package:quaidtech/screens/signup.dart';
import 'package:quaidtech/screens/splashscreen.dart';
import 'package:quaidtech/screens/stastics.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
     
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "KumbhSans"),
      initialRoute: 'splash',
      routes: {
        'login': (context) => const LoginScreen(),
         
        'signup': (context) => const SignUpScreen(),
        'nscreen': (context) => const Newscreen(),
        'home': (context) => const HomeScreen(),
        'checkin': (context) => const CheckinScreen(),
        'checkout': (context) => const CheckoutScreen(),
        'notification': (context) => const NotificationScreen(),
         'profile': (context) => const ProfileScreen(),
         'stat': (context) =>const  StatsticsScreen(),
         'adminh': (context) => const AdminHomeScreen(),
          'splash': (context) => const Splashscreen(),
      },
    );
  }
}