import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:intl/intl.dart';

typedef CloseCallback = Function();

class AttendanceService {
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
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      log('Current Position: Lat=${currentPosition.latitude}, Long=${currentPosition.longitude}');

      double targetLatitude = 33.6084954;
      double targetLongitude = 73.017087;

      // double targetLatitude = 37.4219983;
      // double targetLongitude = -122.084;

      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitude,
        targetLongitude,
      );

      log('Calculated Distance: $distance meters');

      const double maxRange = 200.0;

      if (distance > maxRange) {
        Navigator.pop(context);

        _showAlertDialog(
          context: context,
          mounted: true,
          title: 'Out of Range',
          image: 'assets/failed.png',
          message: 'You are not within the allowed range to check in.',
          closeCallback: () {},
        );
        return;
      }

      Timestamp checkInTime = Timestamp.now();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yMMMd').format(now);

      await FirebaseFirestore.instance
          .collection("AttendanceDetails")
          .doc(userId)
          .collection("dailyattendance")
          .doc(formattedDate)
          .set({
        'checkIn': checkInTime,
        'checkOut': null,
        'userId': userId,
      });

      _showAlertDialog(
        context: context,
        mounted: true,
        title: 'Checked In',
        image: 'assets/checkin_alert.png',
        message: 'Successfully checked in.',
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

      String errorMessage = 'Something went wrong!';
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        context: context,
        mounted: true,
        title: 'Error',
        image: 'assets/failed.png',
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
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double targetLatitude = 37.4219983;
      double targetLongitude = -122.084;

      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        targetLatitude,
        targetLongitude,
      );

      log('Calculated Distance: $distance meters');

      const double maxRange = 200.0;

      if (distance > maxRange) {
        Navigator.pop(context);

        _showAlertDialog(
          context: context,
          mounted: true,
          title: 'Out of Range',
          image: 'assets/failed.png',
          message: 'You are not within the allowed range to check out.',
          closeCallback: () {},
        );
        return;
      }

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

      _showAlertDialog(
        context: context,
        mounted: true,
        title: 'Checked Out',
        image: 'assets/checkout_alert.png',
        message: 'Successfully checked out.',
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

      String errorMessage = 'Something went wrong!';
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      }

      _showAlertDialog(
        context: context,
        mounted: true,
        title: 'Error',
        image: 'assets/failed.png',
        message: errorMessage,
        closeCallback: () {},
      );
    }
  }
}

void _showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String image,
  required CloseCallback closeCallback,
  required bool mounted,
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
        ),
      );
    },
  );
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
    final DateFormat formatter = DateFormat('hh:mm a');
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Material(
                          elevation: 10,
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            child: Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (checkIn == null && checkOut == null)
                        const Text(
                          'Check In',
                          style: TextStyle(
                            fontSize: 22,
                            height: 0,
                          ),
                        ),
                      if (checkIn != null && checkOut == null)
                        const Text(
                          'Check Out',
                          style: TextStyle(
                            fontSize: 22,
                            height: 0,
                          ),
                        ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Material(
                          elevation: 10,
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
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
                            child: Center(
                              child: Image.asset(
                                'assets/notification_icon.png',
                                height: 30,
                                width: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).colorScheme.secondary,
                      height: 0,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.secondary,
                          height: 0,
                        ),
                      ),
                      Text(
                        ' — ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          height: 0,
                        ),
                      ),
                      Text(
                        formattedDay,
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.secondary,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 85),
                  if (checkIn == null && checkOut == null)
                    GestureDetector(
                      onTap: () async {
                        await _attendanceService.checkIn(context, userId);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                          ),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/checkin_button.png',
                                height: 70,
                                width: 70,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Check In",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 25,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (checkIn != null && checkOut == null)
                    GestureDetector(
                      onTap: () async {
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
                                          Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
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
                                          radius: 25,
                                          backgroundColor:
                                              const Color(0xff3B3A3C),
                                          child: Image.asset(
                                            "assets/warning.png",
                                          ),
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
                                          'Do you want to checkout ?',
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
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Container(
                                                width: 110,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xffECECEC),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      height: 0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                await _attendanceService
                                                    .checkOut(context, userId);
                                              },
                                              child: Container(
                                                width: 110,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'Checkout',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Material(
                            color: Theme.of(context).colorScheme.tertiary,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            elevation: 5,
                            child: const SizedBox(
                              width: 280,
                              height: 280,
                            ),
                          ),
                          Material(
                            color: Theme.of(context).colorScheme.surface,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            elevation: 10,
                            child: const SizedBox(
                              width: 200,
                              height: 200,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/checkout_button.png',
                                height: 70,
                                width: 70,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Check Out",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 25,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 5,
                        child: SizedBox(
                          height: screenHeight * 0.14,
                          width: screenWidth * 0.29,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/checkin_time.png',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Text(
                                  _formatTime(checkIn),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 0,
                                  ),
                                ),
                                Container(
                                  height: 25,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Check In',
                                      style: TextStyle(
                                        height: 0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 5,
                        child: SizedBox(
                          height: screenHeight * 0.14,
                          width: screenWidth * 0.29,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/checkout_time.png',
                                  color: Theme.of(context).colorScheme.primary,
                                  height: 26,
                                  width: 26,
                                  fit: BoxFit.fitHeight,
                                ),
                                Text(
                                  _formatTime(checkOut),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 0,
                                  ),
                                ),
                                Container(
                                  height: 25,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Check Out',
                                      style: TextStyle(
                                        height: 0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 5,
                        child: SizedBox(
                          height: screenHeight * 0.14,
                          width: screenWidth * 0.29,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/total_hrs.png',
                                  color: Theme.of(context).colorScheme.primary,
                                  height: 26,
                                  width: 26,
                                  fit: BoxFit.fitHeight,
                                ),
                                Text(
                                  totalHours,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 0,
                                  ),
                                ),
                                Container(
                                  height: 25,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Total Hrs',
                                      style: TextStyle(
                                        height: 0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
