import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quaidtech/screens/login.dart';
import 'package:quaidtech/screens/notification.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

typedef CloseCallback = Function();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final prefs = SharedPreferences.getInstance();
  bool isEdited = false;
  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          if (mounted) {
            setState(() {
              _imageUrl = data['profileImageUrl'];
              _nameController.text = data['name'] ?? '';
              _phoneController.text = data['phone'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Something went wrong';
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
      if (mounted) {
        Navigator.pop(context);
        _showAlertDialog(
          title: 'Error',
          image: 'assets/failed.png',
          message: errorMessage,
          closeCallback: () {},
        );
      }
      log(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImageToFirebase(image);
      }
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = 'Something went wrong';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        title: 'Error',
        image: 'assets/failed.png',
        message: errorMessage,
        closeCallback: () {},
      );
      log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({'profileImageUrl': imageUrl});

      setState(() {
        _imageUrl = imageUrl;
      });
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = 'Something went wrong';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        title: 'Error',
        image: 'assets/failed.png',
        message: errorMessage,
        closeCallback: () {},
      );
      log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateUserData(
      String uid, String name, String phone, String password) async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      log('Current user email: ${user?.email}');

      log('The value of $password');

      await FirebaseFirestore.instance.collection("Users").doc(uid).update(
        {
          'name': name,
          'phone': phone,
        },
      );

      if (password.isNotEmpty && user != null) {
        await user.updatePassword(password);
        log('Password updated successfully');
      }

      _showAlertDialog(
        title: 'Success',
        image: 'assets/success.png',
        message: 'Profile Updated',
        closeCallback: () {},
      );
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = 'Something went wrong';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        title: 'Error',
        image: 'assets/failed.png',
        message: errorMessage,
        closeCallback: () {},
      );
      log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> reauthenticateAndSaveChanges(String password) async {
  //   try {
  //     User? user = _auth.currentUser;

  //     AuthCredential credential = EmailAuthProvider.credential(
  //       email: user!.email!,
  //       password: password,
  //     );

  //     log('The value of $password');

  //     await user.reauthenticateWithCredential(credential);

  //     log('Reauth is working');

  //     updateUserData(
  //       user.uid,
  //       _nameController.text,
  //       _phoneController.text,
  //       _passwordController.text,
  //     );
  //   } catch (e) {
  //     log("Reauthentication failed. Please check your password.");
  //   }
  // }

  Future<void> _logout(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _auth.signOut();

      _showAlertDialog(
        title: 'Logged Out',
        image: 'assets/logout.png',
        message: 'You have successfully logged out.',
        closeCallback: () {},
      );
    } catch (e) {
      Navigator.pop(context);
      _showAlertDialog(
        title: 'Error',
        image: 'assets/error.png',
        message: 'Failed to log out. Please try again.',
        closeCallback: () {},
      );
      log(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                    CircleAvatar(
                      radius: 25.sp,
                      backgroundColor: const Color(0xff3B3A3C),
                      child: Image.asset(
                        "assets/warning.png",
                      ),
                    ),
                    SizedBox(height: 6.sp),
                    Text(
                      'Are you sure ?',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        height: 0.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.sp),
                    Text(
                      'Do you want to logout??',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Colors.grey,
                        height: 0.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15.sp),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 120.sp,
                            height: 40.sp,
                            decoration: BoxDecoration(
                              color: const Color(0xffECECEC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _logout(context);
                          },
                          child: Container(
                            width: 120.sp,
                            height: 40.sp,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _toggleEdit() {
    setState(() {
      isEdited = !isEdited;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            closeCallback();
            if (title == 'Logged Out') {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            } else if (message == 'Profile Updated') {
              Navigator.pop(context);
              setState(() {
                isEdited = false;
              });
              _loadUserProfile();
            } else {
              Navigator.pop(context);
            }
          }
        });
        final Size screenSize = MediaQuery.of(context).size;

        final double screenWidth = screenSize.width;

        double baseFontSize15 = 15;
        double responsiveFontSize15 = baseFontSize15 * (screenWidth / 375);

        return PopScope(
          canPop: false,
          child: Dialog(
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
                      Image.asset(image, width: 50.sp, height: 50.sp),
                      SizedBox(height: 20.sp),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 20;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    double baseFontSize1 = 14;
    double responsiveFontSize1 = baseFontSize1 * (screenWidth / 375);
    double baseFontSize2 = 16;
    double responsiveFontSize2 = baseFontSize2 * (screenWidth / 375);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: screenSize.width * 0.18),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              child: Material(
                borderRadius: BorderRadius.circular(12),
                elevation: 5,
                color: Theme.of(context).colorScheme.tertiary,
                child: SizedBox(
                  width: screenSize.width * 0.12,
                  height: screenSize.height * 0.06,
                  child: Center(
                    child: Image.asset(
                      'assets/notification_icon.png',
                      width: screenSize.width * 0.07,
                      height: screenSize.height * 0.07,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20.0.sp,
                vertical: 10.0.sp,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 175.sp,
                          height: 175.sp,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                        ),
                        _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(900),
                                child: Image.file(
                                  _selectedImage!,
                                  width: 175.sp,
                                  height: 175.sp,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(900),
                                    child: Image.network(
                                      _imageUrl!,
                                      width: 165.sp,
                                      height: 165.sp,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 165.sp,
                                    height: 165.sp,
                                    decoration: const BoxDecoration(),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(900),
                                      child: Image.asset(
                                        'assets/ppppp.png',
                                        width: 165.sp,
                                        height: 165.sp,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                        if (isEdited != false)
                          Positioned(
                            bottom: 0,
                            right: 5,
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: Image.asset(
                                    "assets/camera.png",
                                    width: 20,
                                    height: 20,
                                    color: Colors.white,
                                  )),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: TextStyle(
                                fontSize: responsiveFontSize2,
                                fontWeight: FontWeight.w500,
                                height: 0,
                              ),
                            ),
                            SizedBox(
                              height: screenSize.height * 0.011,
                            ),
                            SizedBox(
                              height: screenSize.height * 0.07,
                              child: TextFormField(
                                controller: _nameController,
                                enabled: isEdited,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username cannot be empty';
                                  }
                                  if (value.length < 5) {
                                    return 'Username must be at least 5 characters long';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: responsiveFontSize2,
                                    color: Colors.grey,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: responsiveFontSize2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (isEdited != false)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: screenSize.height * 0.011,
                                  ),
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: responsiveFontSize2,
                                      fontWeight: FontWeight.w500,
                                      height: 0,
                                    ),
                                  ),
                                  SizedBox(
                                    height: screenSize.height * 0.011,
                                  ),
                                  SizedBox(
                                    height: screenSize.height * 0.07,
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      enabled: isEdited,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password cannot be empty';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'New Password',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintStyle: TextStyle(
                                          fontSize: responsiveFontSize2,
                                          color: Colors.grey,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            size: responsiveFontSize,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: responsiveFontSize2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            SizedBox(
                              height: screenSize.height * 0.011,
                            ),
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: responsiveFontSize2,
                                fontWeight: FontWeight.w500,
                                height: 0,
                              ),
                            ),
                            SizedBox(
                              height: screenSize.height * 0.011,
                            ),
                            SizedBox(
                              height: screenSize.height * 0.07,
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                enabled: isEdited,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Phone cannot be empty';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: responsiveFontSize2,
                                    color: Colors.grey,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: responsiveFontSize2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: screenSize.height * 0.02,
                            ),
                            if (!isEdited)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _toggleEdit,
                                    child: Container(
                                      width: screenSize.width * 0.38,
                                      height: screenSize.height * 0.055,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                          child: Text(
                                        'Edit Profile',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: responsiveFontSize1,
                                        ),
                                      )),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showLogoutConfirmationDialog(context);
                                    },
                                    child: Container(
                                      width: screenSize.width * 0.38,
                                      height: screenSize.height * 0.055,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                          child: Text(
                                        'Log Out',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: responsiveFontSize1,
                                        ),
                                      )),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isEdited) {
                                        _toggleEdit();
                                      }
                                    },
                                    child: Container(
                                      width: screenSize.width * 0.38,
                                      height: screenSize.height * 0.055,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: responsiveFontSize1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => updateUserData(
                                      _auth.currentUser!.uid,
                                      _nameController.text,
                                      _phoneController.text,
                                      _passwordController.text,
                                    ),
                                    child: Container(
                                      width: screenSize.width * 0.38,
                                      height: screenSize.height * 0.055,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                          child: Text(
                                        'Save Changes',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: responsiveFontSize1),
                                      )),
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color.fromARGB(55, 0, 0, 0),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
