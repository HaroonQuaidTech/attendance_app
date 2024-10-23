// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, use_build_context_synchronously, unused_import, avoid_print
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/login.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:quaidtech/screens/splashscreen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _PrifileScreenState();
}

class _PrifileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool isEdited = false;
  File? _selectedImage;
  String? _imageUrl;
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> updateUserData(
      String uid, String email, String name, String phone) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      await firestore.collection("Users").doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
      }, SetOptions(merge: true));
      setState(() {
        isEdited = false;
      });

      Navigator.of(context).pop();
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => Splashscreen()),
      // );

      showToastMessage('Profile and Data Updated successfully');
    } catch (e) {
      Navigator.of(context).pop();
      showToastMessage(e.toString());
      print('$e');
    }
  }

  Future<void> _loadUserProfile() async {
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
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path); // Update the selected image
      });
      await _uploadImageToFirebase(image);
    }
  }

  Future<void> _uploadImageToFirebase(XFile image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({'profileImageUrl': imageUrl});

      setState(() {
        _imageUrl = imageUrl;
      });

      showToastMessage('Image uploaded successfully');
    } catch (e) {
      showToastMessage('Failed to upload image');
    }
  }

  Future<void> _logout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    await _auth.signOut();

    Navigator.of(
      context,
    ).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
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

  void _toggleEdit() {
    setState(() {
      isEdited = !isEdited;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.transparent, // light background color
                            borderRadius:
                                BorderRadius.circular(12), // rounded corners
                            boxShadow: [
                              BoxShadow(
                                color: Colors.transparent,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                              );
                            },
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        Text(
                          'Profile',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                offset: Offset(0, 4),
                                spreadRadius: 0,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => NotificationScreen()),
                              );
                            },
                            child: Image.asset(
                              'assets/notification_icon.png',
                              height: 30,
                              width: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Circle

                      // Middle Circle
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),

                      // Inner Circle with Icon and Text
                      _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(900),
                              child: Image.file(
                                _selectedImage!,
                                width: 175,
                                height: 175,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(900),
                                  child: Image.network(
                                    _imageUrl!,
                                    width: 175,
                                    height: 175,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 175,
                                  height: 175,
                                  decoration: BoxDecoration(),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(900),
                                    child: Image.asset(
                                      'assets/aabb.jpg',
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                      if (isEdited != false)
                        Positioned(
                          bottom: 5,
                          right: 4,
                          child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(20)),
                              child: IconButton(
                                  onPressed: _pickImage,
                                  icon: Icon(
                                    Icons.camera_enhance,
                                    size: 28,
                                  ))),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                    // height: screenHeight * 0.48,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Color(0xffEFF1FF),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username cannot be empty';
                              } else if (value.length < 3) {
                                return 'Username must be at least 3 characters long';
                              }
                              return null;
                            },
                            enabled: isEdited,
                            decoration: InputDecoration(
                              filled: true, // Enable background color
                              fillColor: Colors.white,
                              hintText: 'Username',
                              border: InputBorder.none,
                              // Outlined border
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your email";
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Enter a valid email ';
                              }
                              return null;
                            },
                            enabled: isEdited,
                            decoration: InputDecoration(
                              filled: true, // Enable background color
                              fillColor: Colors.white,
                              hintText: 'user.name@gmail.com',
                              border: InputBorder.none,
                              // Outlined border
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Phone Number',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: TextFormField(
                            controller: _phoneController,

                            keyboardType: TextInputType
                                .phone, // Set keyboard type to phone
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone number cannot be empty';
                              } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Phone number can only contain digits';
                              } else if (value.length != 10) {
                                return 'Phone number must be 10 digits long';
                              }
                              return null; // Return null if the input is valid
                            },
                            enabled: isEdited,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter your Phone Number',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        if (!isEdited)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _toggleEdit,
                                child: Container(
                                  width: screenWidth * 0.4,
                                  height: screenHeight * 0.055,
                                  decoration: BoxDecoration(
                                    color: Color(0xff7647EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                      child: Text(
                                    'Edit Profile',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          AlertDialog(
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    top: 60.0),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            title: Column(
                                              children: [
                                                Text(
                                                  'Are you Sure',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  'Do you want to logout ?',
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 15),
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
                                                          color:
                                                              Colors.grey[400],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Cancel',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
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
                                                                  .circular(5),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            'Logout',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
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
                                          Positioned(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                (280 / 812),
                                            child: Image.asset(
                                              'assets/warning_alert.png',
                                              width: 60, // Adjust as needed
                                              height: 60, // Adjust as needed
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: screenWidth * 0.4,
                                  height: screenHeight * 0.055,
                                  decoration: BoxDecoration(
                                    color: Color(0xffEC5851),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                      child: Text(
                                    'Log Out',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => updateUserData(
                                    FirebaseAuth.instance.currentUser!.uid,
                                    _emailController.text.trim(),
                                    _nameController.text.trim(),
                                    _phoneController.text.trim()),
                                child: Container(
                                  width: screenWidth * 0.4,
                                  height: screenHeight * 0.055,
                                  decoration: BoxDecoration(
                                    color: Color(0xff7647EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                      child: Text(
                                    'Save Changes',
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
