// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quaidtech/screens/adminhome.dart';
import 'package:quaidtech/screens/login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
   void _checkUserLogin() async {
    await Future.delayed(Duration(milliseconds: 1)); // Simulate a splash delay

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
    
      Navigator.pushReplacementNamed(context, 'home');
    } else {
   
      Navigator.pushReplacementNamed(context, 'login');
    }
  }


  @override
  void initState() {

    _checkUserLogin();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
              SizedBox(height: 10),
                  Center(
                      child: SizedBox(
                          height: 100, child: Image.asset('assets/logo.png'))),
                          SizedBox(height: 50),
          
          SizedBox(
            width: 330,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder:(context)=> LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                elevation: 5, // Elevation (shadow)
              ),
              child: Text(
                'User Panel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
SizedBox(height: 40,),
         SizedBox(
          width: 330,
           child: ElevatedButton(
             onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder:(context)=> AdminHomeScreen()));
             },
             style: ElevatedButton.styleFrom(
               foregroundColor: Colors.white, backgroundColor: Color(0xff8E71DF), // Text color
               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Padding
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(10), // Rounded corners
               ),
               elevation: 5, // Elevation (shadow)
             ),
             child: Text(
               'Admin Panel',
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ),
         )
        ],
      ),
    );
  }
}