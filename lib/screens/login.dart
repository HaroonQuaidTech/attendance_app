// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_field, prefer_final_fields, unused_element, use_build_context_synchronously, unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isCheck = false;
  bool isPasswordVisible = false;

  void _toggleCheckbox(bool? value) {
    setState(() {
      _isCheck = value ?? false;
    });
  }

  Future<void> _login(BuildContext context) async {
    String email = _emailController.text;
    String password = _passwordController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      Navigator.pop(context);

      await Future.delayed(Duration(seconds: 3));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      showToastMessage('User is logged in successfully');
    } catch (e) {
      Navigator.pop(context);

      showToastMessage('Error: $e');
    }
  }

  void showToastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF8F8FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hi, Welcome Back! 👋',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hello again, you’ve been missed!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  Image.asset('assets/img1.png'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    height: 360,
                    decoration: BoxDecoration(
                        color: Color(0xffEFF1FF),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text('Log In',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          'Email Address',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true, // Enable background color
                              fillColor: Colors.white,
                              hintText: 'Enter your Email Address',
                              border: InputBorder.none,
                              // Outlined border
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text('Password',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: isPasswordVisible,
                            decoration: InputDecoration(
                                suffixIconConstraints:
                                    BoxConstraints(maxHeight: 20),
                                filled: true, // Enable background color
                                fillColor: Colors.white,
                                hintText: 'Enter your Password',
                                border: InputBorder.none,
                                suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6.0),
                                      child: Icon(isPasswordVisible
                                          ? Icons.remove_red_eye
                                          : Icons.visibility_off),
                                    ))),
                          ),
                        ),

                        // Container(
                        //   padding: EdgeInsets.symmetric(horizontal: 3),
                        //   decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       borderRadius: BorderRadius.circular(8)),
                        //   child: TextFormField(
                        //     // obscureText: isPasswordVisible,
                        //     decoration: InputDecoration(
                        //         hintText: 'Enter your Password',
                        //         border: InputBorder.none,
                        //         // suffixIcon: IconButton(onPressed: (){setState(() {
                        //         //   isPasswordVisible=!isPasswordVisible;
                        //         // });}, icon: Icon(isPasswordVisible?Icons.remove_red_eye:Icons.visibility_off)),

                        //         // suffixIconColor: Colors.grey

                        //         ),

                        //   ),
                        // ),
                        Row(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20)),
                                child: Checkbox(
                                    value: _isCheck,
                                    onChanged: _toggleCheckbox)),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15),
                            )
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            _login(context);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(0xff7647EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                                child: Text(
                              'Log In',
                              style: TextStyle(color: Colors.white),
                            )),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already Have An Account',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 10,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignUpScreen()),
                                );
                              },
                              child: Text('Sign Up',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff7647EB),
                                  )),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                      child: SizedBox(
                          height: 60, child: Image.asset('assets/logo.png'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
