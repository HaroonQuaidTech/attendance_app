import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/login.dart';

typedef CloseCallback = Function();

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
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
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            _imageUrl = data['profileImageUrl'];
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          });
        }
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

      // Update the Firestore data
      await FirebaseFirestore.instance.collection("Users").doc(uid).set({
        'name': name,
        'phone': phone,
      }, SetOptions(merge: true));

      if (password.isNotEmpty && user != null) {
        await user.updatePassword(password);
        log('Password updated successfully');
      }

      _showAlertDialog(
        title: 'Success',
        image: 'assets/success.png',
        message: 'Profile Updated',
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

  Future<void> _logout(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _auth.signOut();

      setState(() {
        _isLoading = false;
      });

      _showAlertDialog(
        title: 'Logged Out',
        image: 'assets/logout.png',
        message: 'You have successfully logged out.',
        closeCallback: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showAlertDialog(
        title: 'Error',
        image: 'assets/error.png',
        message: 'Failed to log out. Please try again.',
        closeCallback: () {},
      );
    }
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
            Navigator.of(context).pop(true);
            closeCallback();
          }
        });
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
                  height: 10,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff4D3D79),
                        Color(0xff8E71DF),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.vertical(
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
                          fontSize: 10,
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
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                    _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(90),
                            child: Image.file(
                              _selectedImage!,
                              width: 175,
                              height: 175,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _imageUrl != null && _imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(90),
                                child: Image.network(
                                  _imageUrl!,
                                  width: 175,
                                  height: 175,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(90),
                                child: Image.asset(
                                  'assets/aabb.jpg',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                    Positioned(
                      bottom: 5,
                      right: 4,
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(
                          Icons.camera_enhance,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xffEFF1FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
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
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible, // Toggle visibility
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
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                updateUserData(
                                  _auth.currentUser!.uid,
                                  _nameController.text,
                                  _phoneController.text,
                                  _passwordController.text,
                                );
                              },
                              child: const Text('Update Profile'),
                            ),
                            GestureDetector(
                              onTap: () {
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
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xff4D3D79),
                                                  Color(0xff8E71DF),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.vertical(
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
                                                  "assets/warning.png",
                                                  width: 50,
                                                  height: 50,
                                                ),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  'Are you sure ?',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    height: 0,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  'Do you want to logout ?',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                    height: 0,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Container(
                                                        width: 110,
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xffECECEC),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.black,
                                                              height: 0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        _logout(context);
                                                      },
                                                      child: Container(
                                                        width: 110,
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xff7647EB),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'Logout',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
                                                              height: 0,
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
                              },
                              child: Container(
                                width: 80,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xffEC5851),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                    child: Text(
                                  'Log Out',
                                  style: TextStyle(color: Colors.white),
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
