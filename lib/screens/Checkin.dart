// ignore_for_file: use_build_context_synchronously, duplicate_ignore, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:intl/intl.dart';

typedef CloseCallback = Function();

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkIn(BuildContext context, String userId) async {
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
      Timestamp checkInTime = Timestamp.now();
      DateTime now = DateTime.now();

      String formattedDate = DateFormat('yMMMd').format(now);

      await _firestore
          .collection("AttendanceDetails")
          .doc(userId)
          .collection("dailyattendance")
          .doc(formattedDate)
          .set({
        'checkIn': checkInTime,
        'checkOut': null,
        'userId': userId,
      });

      Navigator.pop(context);

      _showAlertDialog(
        context: context,
        title: 'Successful',
        titleColor: Colors.green,
        image: 'assets/success_alert.png',
        message: 'Checked in successfully!',
        closeCallback: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      String errorMessage = 'Something went wrong!';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        // ignore: use_build_context_synchronously
        context: context,
        title: 'Error',
        titleColor: Colors.red,
        image: 'assets/failed_alert.png',
        message: errorMessage,
        closeCallback: () {},
      );
    }
  }

  Future<void> checkOut(BuildContext context, String userId) async {
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
      Timestamp checkOutTime = Timestamp.now();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yMMMd').format(now);

      await FirebaseFirestore.instance
          .collection("AttendanceDetails")
          .doc(userId)
          .collection("dailyattendance")
          .doc(formattedDate)
          .update({
        'checkOut': checkOutTime,
      });

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      String errorMessage = 'Something went wrong!';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }
    }
  }
}

void _showAlertDialog({
  required BuildContext context,
  required String title,
  required Color titleColor,
  required String message,
  required String image,
  required VoidCallback closeCallback,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            contentPadding: const EdgeInsets.only(top: 60.0),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          Positioned(
            top: 260,
            child: Image.asset(
              image,
              width: 60,
              height: 60,
            ),
          ),
        ],
      );
    },
  ).then((_) {
    closeCallback(); // Call the callback after closing the alert dialog
  });
}

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> _getAttendanceDetails(String uid) async {
    String formattedDate = DateFormat('yMMMd').format(DateTime.now());
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('AttendanceDetails')
            .doc(userId)
            .collection('dailyattendance')
            .doc(formattedDate)
            .get();

    if (snapshot.exists) {
      return snapshot.data();
    }
    return null;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final DateFormat formatter =
        DateFormat('hh:mm a'); // Format to display only time
    return formatter.format(dateTime);
  }

  String _calculateTotalHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) {
      return "--:--";
    }

    Duration duration = checkOut.difference(checkIn);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    final String formattedHours = hours.toString().padLeft(2, '0');
    final String formattedMinutes = minutes.toString().padLeft(2, '0');

    return '$formattedHours:$formattedMinutes';
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    DateTime now = DateTime.now();

    // Format date, day, and time
    String formattedDate = DateFormat('yMMMd').format(now);
    String formattedDay = DateFormat('EEEE').format(now);
    String formattedTime = DateFormat('hh:mm a').format(now);
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getAttendanceDetails(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          DateTime? checkIn;
          DateTime? checkOut;

          if (!(!snapshot.hasData || snapshot.data == null)) {
            final data = snapshot.data!;

            checkIn = (data['checkIn'] as Timestamp?)?.toDate();
            checkOut = (data['checkOut'] as Timestamp?)?.toDate();
          }

          DateTime now = DateTime.now();
          DateTime currentDayStart = DateTime(now.year, now.month, now.day);
          if (checkIn != null && checkIn.isBefore(currentDayStart)) {
            checkIn = null;
            checkOut = null;
          }

          if (checkOut != null) {
            DateTime nextDay7AM = DateTime(now.year, now.month, now.day, 7, 0);
            if (now.isAfter(nextDay7AM)) {
              checkIn != null;
            } else {
              formattedDate = DateFormat('yyyy-MM-dd').format(now);
            }
          }

          final totalHours = _calculateTotalHours(checkIn, checkOut);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    height: 70,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200], // light background color
                              borderRadius:
                                  BorderRadius.circular(12), // rounded corners
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (checkIn == null && checkOut == null)
                            const Text(
                              'Check In',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                height: 0,
                              ),
                            ),
                          if (checkIn != null && checkOut == null)
                            const Text(
                              'Check Out',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                height: 0,
                              ),
                            ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200], // light background color
                              borderRadius:
                                  BorderRadius.circular(12), // rounded corners
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.notifications_none,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 40,
                      color: Color(0xff7647EB),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 20, color: Color(0xff7647EB)),
                      ),
                      Text(
                        ' $formattedDay',
                        style: const TextStyle(
                            fontSize: 20, color: Color(0xff7647EB)),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.14),
                  //--------------------Check iN-------------------------
                  if (checkIn == null && checkOut == null)
                    GestureDetector(
                      onTap: () async {
                        Position currentPosition =
                            await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );

                        // Target coordinates
                        double targetLatitude = 33.6084548;
                        double targetLongitude = 73.0171062;

                        double distanceInMeters = Geolocator.distanceBetween(
                          currentPosition.latitude,
                          currentPosition.longitude,
                          targetLatitude,
                          targetLongitude,
                        );

                        // ignore: use_build_context_synchronously
                        await _attendanceService.checkIn(context, userId);

                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop(true);
                          CloseCallback;
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Circle
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                  color: const Color(0xff7647EB), width: 2),
                            ),
                          ),
                          // Middle Circle
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                  color: const Color(0xff7647EB), width: 2),
                            ),
                          ),
                          // Inner Circle with Icon and Text
                          Container(
                            width: 115,
                            height: 115,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/mingcute.png',
                                  height: 42,
                                  width: 42,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Check In",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  //----------------------------------------check out----------------------------------------------------------
                  if (checkIn != null && checkOut == null)
                    GestureDetector(
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                AlertDialog(
                                  contentPadding: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.height *
                                          0.1),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: Column(
                                    children: [
                                      Text(
                                        'Are you Sure',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05, // Responsive font size
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        'Do you want to checkout ?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04, // Responsive font size
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3, // Responsive width
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05, // Responsive height
                                              decoration: BoxDecoration(
                                                color: Colors.grey[400],
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width *
                                                        0.04, // Responsive font size
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              Position currentPosition =
                                                  await Geolocator
                                                      .getCurrentPosition(
                                                desiredAccuracy:
                                                    LocationAccuracy.high,
                                              );

                                              // Target coordinates
                                              double targetLatitude =
                                                  33.6084548;
                                              double targetLongitude =
                                                  73.0171062;

                                              double distanceInMeters =
                                                  Geolocator.distanceBetween(
                                                currentPosition.latitude,
                                                currentPosition.longitude,
                                                targetLatitude,
                                                targetLongitude,
                                              );

                                              await _attendanceService.checkOut(
                                                  // ignore: use_build_context_synchronously
                                                  context,
                                                  userId);
                                            },
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3, // Responsive width
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.05, // Responsive height
                                              decoration: BoxDecoration(
                                                color: const Color(0xff7647EB),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Checkout',
                                                  style: TextStyle(
                                                    fontSize: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width *
                                                        0.04, // Responsive font size
                                                    color: Colors.white,
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
                                  top:
                                      MediaQuery.of(context).size.height * 0.34,
                                  child: Image.asset(
                                    'assets/warning_alert.png',
                                    width: MediaQuery.of(context).size.width *
                                        0.15, // Responsive width
                                    height: MediaQuery.of(context).size.width *
                                        0.15, // Responsive height
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Circle
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(12, 12),
                                  blurRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                  color: const Color(0xffFB3F4A), width: 2),
                            ),
                          ),
                          // Middle Circle
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(8, 8),
                                  blurRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                  color: const Color(0xffFB3F4A), width: 2),
                            ),
                          ),
                          // Inner Circle with Icon and Text
                          Container(
                            width: 115,
                            height: 115,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/mingout.png',
                                  height: 42,
                                  width: 42,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Check Out",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(
                    height: 30,
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 140,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: screenHeight * 0.46,
                            width: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF1FF),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image.asset(
                                  'assets/checkin.png',
                                  height: 42,
                                  width: 42,
                                ),
                                Text(
                                  _formatTime(checkIn),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Check In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.46,
                            width: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF1FF),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image.asset(
                                  'assets/checkout.png',
                                  height: 42,
                                  width: 42,
                                ),
                                Text(
                                  _formatTime(checkOut),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Check Out',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: screenHeight * 0.46,
                            width: screenWidth * 0.3,
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF1FF),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Image.asset(
                                  'assets/total_hrs.png',
                                  height: 45,
                                  width: 45,
                                  color: const Color(0xff7647EB),
                                ),
                                Text(
                                  totalHours,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Total Hrs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
