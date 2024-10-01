// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_new, avoid_print, sort_child_properties_last, unused_local_variable, unnecessary_string_interpolations, depend_on_referenced_packages, use_key_in_widget_constructors
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quaidtech/components/dailyAttendancedetails.dart';
import 'package:quaidtech/components/dailyNullAttend.dart';

import 'package:quaidtech/components/monthlyattendance.dart';
import 'package:quaidtech/screens/Checkin.dart';
import 'package:quaidtech/screens/notification.dart';
import 'package:quaidtech/screens/profile.dart';
import 'package:quaidtech/screens/stastics.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// import 'package:circular_progress_stack/circularprogressstack.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _imageUrl;
  bool isCheck = false;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _selectedIndex = 0;

  Future<Map<String, dynamic>?> _getAttendanceDetails(
      String uid, DateTime day) async {
    String formattedDate = DateFormat('yMMMd').format(day);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('AttendanceDetails')
            .doc(userId)
            .collection('dailyattendance')
            .doc('$formattedDate')
            .get();

    if (snapshot.exists) {
      return snapshot.data();
    }
    return null;
  }

  void _showAttendanceDetails(Map<String, dynamic> data) {
    log(' data1 $data', name: 'Logg');
    DateTime? checkInTime = (data['checkIn'] != null)
        ? (data['checkIn'] as Timestamp).toDate()
        : null;
    DateTime? checkOutTime = (data['checkOut'] != null)
        ? (data['checkOut'] as Timestamp).toDate()
        : null;
    String checkInTimeFormatted =
        checkInTime != null ? DateFormat('hh:mm:a').format(checkInTime) : 'N/A';
    String checkOutTimeFormatted = checkOutTime != null
        ? DateFormat('hh:mm:a').format(checkOutTime)
        : 'N/A';

    String tatFormatted;
    if (checkOutTime != null && checkInTime != null) {
      Duration tat = checkOutTime.difference(checkInTime);
      tatFormatted = "${tat.inHours}h ${tat.inMinutes.remainder(60)}m";
    } else {
      tatFormatted = "N/A"; // If check-in or check-out is null
    }
  }

  void _showNoDataMessage() {}

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      data = await _getAttendanceDetails(userId, selectedDay);

      setState(() {
        if (data != null) {
          _showAttendanceDetails(data!);
        } else {
          _showNoDataMessage();
        }
      });
    } catch (e) {
      log('Error fetching attendance details: $e');
      setState(() {
        _showNoDataMessage();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  Future<Map<String, int>> fetchMonthlyAttendance(String userId) async {
    final now = DateTime.now();
    final attendanceCollection = FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(userId)
        .collection('dailyattendance');

    try {
      final querySnapshot = await attendanceCollection.get();

      if (querySnapshot.docs.isEmpty) {
        return {'present': 0, 'late': 0, 'absent': 0};
      }

      final lateThreshold = DateTime(now.year, now.month, now.day, 8, 15);

      final counts = querySnapshot.docs.fold<Map<String, int>>(
        {'present': 0, 'late': 0, 'absent': 0},
        (Map<String, int> accumulator, doc) {
          final data = doc.data();
          final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
          final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

          if (checkIn == null && checkOut == null) {
            accumulator['absent'] = (accumulator['absent'] ?? 0) + 1;
          } else if (checkIn != null) {
            if (checkIn.isAfter(lateThreshold)) {
              accumulator['present'] = (accumulator['present'] ?? 0) + 1;
              accumulator['late'] = (accumulator['late'] ?? 0) + 1;
            } else {
              accumulator['present'] = (accumulator['present'] ?? 0) + 1;
              accumulator['late'] = (accumulator['late'] ?? 0) + 1;
            }

            if (checkOut == null) {
              accumulator['absent'] = (accumulator['absent'] ?? 0) + 1;
            }
          } else {
            accumulator['absent'] = (accumulator['absent'] ?? 0) + 1;
          }

          return accumulator;
        },
      );

      return counts;
    } catch (e) {
      print('Error fetching monthly attendance: $e');
      return {
        'present': 0,
        'late': 0,
        'absent': 0,
      };
    }
  }

  Widget _buildSegmentNavigator(String text, int index, Icon icon) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 16;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    bool isSelected = _selectedIndex == index;
    if (index == 1) StatsticsScreen();
    if (index == 2) ProfileScreen();
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(48.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Icon(
                  icon.icon,
                  color: isSelected ? Color(0xff7647EB) : Color(0xffA4A4A4),
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  text,
                  style: TextStyle(
                      color: isSelected ? Color(0xff7647EB) : Color(0xffA4A4A4),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: responsiveFontSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _loadUserProfile();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String? displayName = user?.displayName ?? "No Name Provided";
    String? email = user?.email ?? "No Email Provided";
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
          context: context,
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
                        'Are you Sure',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Do you want to exit app ?',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 110,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              exit(0);
                            },
                            child: Container(
                              width: 110,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xff7647EB),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  'Continue',
                                  style: const TextStyle(
                                    fontSize: 14,
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
                  top: 260,
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
        return exitApp;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _selectedIndex == 1
              ? StatsticsScreen()
              : _selectedIndex == 2
                  ? ProfileScreen()
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        child: Column(
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(user?.uid)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return Row(children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(80),
                                            child: Image.asset(
                                              'assets/pp.jpg',
                                              height: 60,
                                              width: 60,
                                              fit: BoxFit.cover,
                                            )),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "No Name Provided",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            "No Email Provided",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    NotificationScreen()),
                                          );
                                        },
                                        child: Image.asset(
                                          'assets/icon.png',
                                          height: 72,
                                          width: 72,
                                        ),
                                      )
                                    ]);
                                  }

                                  var userData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  String displayName =
                                      userData['name'] ?? "No Name Provided";
                                  String email =
                                      userData['email'] ?? "No Name Provided";

                                  return Row(children: [
                                    if (_imageUrl != null &&
                                        _imageUrl!.isNotEmpty)
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10.0),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(900),
                                            child: Image.network(
                                              _imageUrl!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "$displayName",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          "$email",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
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
                                                    NotificationScreen()),
                                          );
                                        },
                                        child: Icon(
                                          Icons.notifications_none,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ]);
                                }),
                            SizedBox(
                              height: 30,
                            ),
                            //mothly attendance

                            Container(
                                padding: EdgeInsets.all(12),
                                height: screenHeight * 0.19,
                                decoration: BoxDecoration(
                                  color: Color(0xffEFF1FF),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: FutureBuilder<Map<String, int>>(
                                  future: fetchMonthlyAttendance(user!.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    }

                                    if (snapshot.hasData) {
                                      final data = snapshot.data!;

                                      if (data['present'] == 0 &&
                                          data['late'] == 0 &&
                                          data['absent'] == 0) {
                                        return Center(
                                            child: Text(
                                                'No attendance records available for this month.'));
                                      }

                                      return Monthlyattendance(
                                        presentCount: data['present']!,
                                        lateCount: data['late']!,
                                        absentCount: data['absent']!,
                                      );
                                    }

                                    return Center(
                                        child: Text('No data available.'));
                                  },
                                )),
                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffEFF1FF),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2020, 10, 16),
                                lastDay: DateTime.utc(2030, 3, 14),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                availableCalendarFormats: const {
                                  CalendarFormat.month: 'Month',
                                },
                                headerVisible: true,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: _onDaySelected,
                                onFormatChanged: (format) {
                                  if (_calendarFormat != format) {
                                    setState(() {
                                      _calendarFormat = format;
                                    });
                                  }
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                              ),
                            ),

                            SizedBox(
                              height: 20,
                            ),
                            Container(
                              height: 142,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Color(0xffEFF1FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(4, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendance Details',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 6),
                                      Builder(builder: (context) {
                                        if (data == null) {
                                          return DailyEmptyAttendance(
                                              selectedDay: _selectedDay);
                                        }

                                        return DailyAttendance(
                                            data: data,
                                            selectedDay: _selectedDay);
                                      }),
                                    ],
                                  )),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
        floatingActionButton: _selectedIndex == 0
            ? DraggableFab(
                child: Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Circle
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xff8E71DF).withOpacity(0.5),
                            width: 2.0,
                          ),
                        ),
                      ),
                      // Middle Circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xff8E71DF).withOpacity(0.7),
                            width: 2.0,
                          ),
                        ),
                      ),
                      // Floating Action Button

                      // if (!snapshot.hasData || snapshot.data == null) {
                      //   return Center(
                      //       child: Text('No attendance data found.'));
                      // }

                      // // final data = snapshot.data!;
                      // final checkIn =
                      //     (data['checkIn'] as Timestamp?)?.toDate();
                      // final checkOut =
                      //     (data['checkOut'] as Timestamp?)?.toDate();

                      FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CheckinScreen()),
                          );
                        },
                        backgroundColor: Color(0xffEFF1FF),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(100), // Set border radius
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/mingcute.png',
                              height: 28,
                              width: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Check In',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Container(
            height: 65,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: Color(0xffEFF1FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSegmentNavigator('Home', 0, Icon(Icons.home)),
                _buildSegmentNavigator(
                    'Stats', 1, Icon(Icons.graphic_eq_outlined)),
                _buildSegmentNavigator('Profile', 2, Icon(Icons.person)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
