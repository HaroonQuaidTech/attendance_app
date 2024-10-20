import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:intl/intl.dart';

typedef CloseCallback = Function();

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkIn(String userId) async {
    try {
      Timestamp checkInTime = Timestamp.now();
      DateTime now = DateTime.now();

      String formattedDate =
          DateFormat('yMMMd').format(now); // Example: Sep 3, 2024

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

      log("Checked in successfully");
    } catch (e) {
      log("Error checking in: $e");
    }
  }

  Future<void> checkOut(String userId) async {
    try {
      Timestamp checkOutTime = Timestamp.now();
      DateTime now = DateTime.now();

      String formattedDate = DateFormat('yMMMd').format(now);

      await _firestore
          .collection("AttendanceDetails")
          .doc(userId)
          .collection("dailyattendance")
          .doc(formattedDate)
          .update({
        'checkOut': checkOutTime,
      });

      log("Checked out successfully");
    } catch (e) {
      log("Error checking out: $e");
    }
  }
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

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      log('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again
        log('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      log('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // When we reach here, permissions are granted and we can get the location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      // _currentPosition = position;
    });

    log('Current location: ${position.latitude}, ${position.longitude}');
  }

  void showToastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER_RIGHT,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
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
    String formattedDate =
        DateFormat('yMMMd').format(now); // Example: Sep 3, 2024
    String formattedDay = DateFormat('EEEE').format(now); // Example: Tuesday
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
              // ignore: unnecessary_null_comparison
              checkOut != null;
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
                        log('Distance to target: $distanceInMeters meters');

                        await _attendanceService.checkIn(userId);
                        showToastMessage('Checked In Successfully');

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
                              clipBehavior: Clip
                                  .none, // Ensures the icon can overflow outside the dialog
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

                                              log('Distance to target: $distanceInMeters meters');

                                              await _attendanceService
                                                  .checkOut(userId);
                                              showToastMessage(
                                                  'Checked Out Successfully');
                                              if (mounted) {
                                                // ignore: use_build_context_synchronously
                                                Navigator.of(context).pop(true);
                                                CloseCallback;
                                              }
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
                                  top: MediaQuery.of(context).size.height *
                                      0.34, // Responsive top position for the image
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
                                  'assets/totalhours.png',
                                  height: 42,
                                  width: 42,
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
