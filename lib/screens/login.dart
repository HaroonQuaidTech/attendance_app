import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    bool isCheck = prefs.getBool('rememberMe') ?? false;

    if (isCheck && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _isCheck = true;
      });
    } else {
      setState(() {
        _emailController.text = '';
        _passwordController.text = '';
        _isCheck = false;
      });
    }
  }

  Future<void> _saveLoginDetails(
      String email, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setBool('rememberMe', rememberMe);
  }

  void _toggleCheckbox(bool? value) {
    setState(() {
      _isCheck = value ?? false;
    });

    _saveLoginDetails(
        _emailController.text, _passwordController.text, _isCheck);
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

      await _saveLoginDetails(email, password, _isCheck);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );

      _showAlertDialog(
        title: 'Success',
        image: 'assets/success.png',
        message: 'Login Successfully',
        closeCallback: () {},
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
        final Size screenSize = MediaQuery.of(context).size;
        final double screenWidth = screenSize.width;

        double baseFontSize18 = 18;
        double responsiveFontSize18 = baseFontSize18 * (screenWidth / 375);

        double baseFontSize15 = 15;
        double responsiveFontSize15 = baseFontSize15 * (screenWidth / 375);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 10.sp,
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
                      width: MediaQuery.of(context).size.height * 0.1,
                      height: MediaQuery.of(context).size.height * 0.1,
                    ),
                    SizedBox(height: screenSize.height * 0.001),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsiveFontSize18,
                        fontWeight: FontWeight.bold,
                        height: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: responsiveFontSize15,
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
                SizedBox(height: 120.sp),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 40.sp,
                    height: 0.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 50.sp),
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      SizedBox(
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
                              size: 22.sp,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.tertiary,
                            hintText: 'Enter your email address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            errorStyle: const TextStyle(height: 0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.sp),
                      Text(
                        'Password',
                        style: TextStyle(
                          height: 0.sp,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 8.sp),
                      TextFormField(
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
                            size: 22.sp,
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
                              color: Theme.of(context).colorScheme.primary,
                              size: 22.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: CheckboxThemeData(
                                side: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _isCheck,
                              onChanged: _toggleCheckbox,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(
                                  horizontal: -4, vertical: -4),
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              height: 0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.sp),
                      GestureDetector(
                        onTap: () {
                          _login(context);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 42.sp,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'LOGIN',
                              style: TextStyle(
                                color: Colors.white,
                                height: 0.sp,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100.sp),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 90.sp,
                    width: 90.sp,
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
