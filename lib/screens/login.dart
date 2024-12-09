import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef CloseCallback = Function();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isCheck = false;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadLoginDetails();
  }

  Future<void> _loadLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _isCheck = true;
      });
    }
  }

  Future<void> _saveLoginDetails(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    if (_isCheck) {
      await prefs.setString('email', email);
      await prefs.setString('password', password);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  void _toggleCheckbox(bool? value) {
    setState(() {
      _isCheck = value ?? false;
    });
  }

  Future<void> _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text;
    String password = _passwordController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      log(userCredential.toString());

      await _saveLoginDetails(email, password);

      _showAlertDialog(
        title: 'Success',
        image: 'assets/success.png',
        message: 'Login Successfully',
        closeCallback: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = 'Invalid Credentials';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        title: 'Error',
        image: 'assets/failed.png',
        message: errorMessage,
        closeCallback: () {},
      );
    }
  }

  void _showAlertDialog({
    required String title,
    required String message,
    required String image,
    required CloseCallback closeCallback,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop(true);
            closeCallback();
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.inversePrimary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      image,
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

      double baseFontSize22 = 22;
    double responsiveFontSize22 = baseFontSize22 * (screenWidth / 375);

    double baseFontSize1 = 40;
    double responsiveFontSize40 = baseFontSize1 * (screenWidth / 375);
    double baseFontSize2 = 16;
    double responsiveFontSize16 = baseFontSize2 * (screenWidth / 375);
    double baseFontSize3 = 14;
    double responsiveFontSize14 = baseFontSize3 * (screenWidth / 375);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
            ),
            child: Column(
              children: [
                SizedBox(height: screenSize.height * 0.1),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: responsiveFontSize40,
                    height: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.06),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Address',
                        style: TextStyle(
                          height: 0,
                          fontSize: responsiveFontSize16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: screenSize.height * 0.07,
                        child: TextFormField(
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.email,
                              color: Theme.of(context).colorScheme.primary,
                              size: responsiveFontSize22,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Enter your email address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Password',
                        style: TextStyle(
                          height: 0,
                          fontSize: responsiveFontSize16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                         height: screenSize.height * 0.07,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password cannot be empty';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.password,
                              color: Theme.of(context).colorScheme.primary,
                              size: responsiveFontSize22,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Enter your password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: responsiveFontSize22,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: CheckboxThemeData(
                                side: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: screenWidth * 0.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _isCheck,
                              onChanged: _toggleCheckbox,
                            ),
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: responsiveFontSize14,
                              height: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _login(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: screenSize.height * 0.05,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                color: Colors.white,
                                height: 0,
                                fontSize: responsiveFontSize14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.09),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 90,
                    width: 90,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
