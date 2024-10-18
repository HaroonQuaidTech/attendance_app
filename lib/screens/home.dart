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

typedef CloseCallback = Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> weeklyData = [];

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _imageUrl;
  bool _isLoading = false;
  int _selectedIndex = 0;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, List<Color>> _events = {
    DateTime.utc(2024, 10, 1): [const Color(0xff8E71DF)],
    DateTime.utc(2024, 10, 2): [const Color(0xffF6C15B)],
  };

  List<Color> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Future<Map<String, dynamic>?> _getAttendanceDetails(
      String uid, DateTime day) async {
    String formattedDate = DateFormat('yMMMd').format(day);

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

  void _showAttendanceDetails(Map<String, dynamic> data) {
    log(' data1 $data', name: 'Logg');
    DateTime? checkInTime = (data['checkIn'] != null)
        ? (data['checkIn'] as Timestamp).toDate()
        : null;
    DateTime? checkOutTime = (data['checkOut'] != null)
        ? (data['checkOut'] as Timestamp).toDate()
        : null;

    if (checkOutTime != null && checkInTime != null) {
      checkOutTime.difference(checkInTime);
    } else {}
  }

  void _showNoDataMessage() {
    log('No attendance data available for the selected day');
  }

  @override
  void initState() {
    super.initState();
    _onItemTapped(0);
    _loadUserProfile();
    _onDaySelected(_selectedDay, _focusedDay);
    _getAttendanceDetails(userId, DateTime.now());
    _fetchEventsForMonth(userId);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isLoading = true;
    });
    String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      data = await _getAttendanceDetails(userId, selectedDay);
      setState(() {
        _isLoading = false;
        if (data != null) {
          _showAttendanceDetails(data!);
        } else {
          _showNoDataMessage();
        }
      });
    } catch (e) {
      log('Error fetching attendance details: $e');
      setState(() {
        _isLoading = false;
        _showNoDataMessage();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchEventsForMonth(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final attendanceCollection = FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(userId)
        .collection('dailyattendance');

    try {
      final querySnapshot = await attendanceCollection
          .where('checkIn', isGreaterThanOrEqualTo: startOfMonth)
          .where('checkIn', isLessThanOrEqualTo: now)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _events.clear();

          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            final checkIn = (data['checkIn'] as Timestamp?)?.toDate();

            if (checkIn != null) {
              final lateThreshold =
                  DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 15);

              // Determine color based on attendance status
              Color eventColor;
              if (checkIn.isAfter(lateThreshold)) {
                eventColor = const Color(0xffF6C15B);
              } else if (checkIn.isBefore(lateThreshold)) {
                eventColor = const Color(0xff22AF41);
              } else {
                eventColor = const Color(0xffEC5851);
              }

              _events[DateTime.utc(checkIn.year, checkIn.month, checkIn.day)] =
                  [eventColor];
            }
          }
        });
      }
    } catch (e) {
      log('Error fetching events: $e');
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

  Future<Map<String, int>> fetchMonthlyAttendance(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final attendanceCollection = FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(userId)
        .collection('dailyattendance');

    try {
      final querySnapshot = await attendanceCollection
          .where('checkIn', isGreaterThanOrEqualTo: startOfMonth)
          .where('checkIn', isLessThanOrEqualTo: now)
          .get();

      final currentDayOfMonth = now.day;

      Map<String, int> counts = {
        'present': 0,
        'late': 0,
        'absent': 0,
      };

      if (querySnapshot.docs.isEmpty) {
        return {'present': 0, 'late': 0, 'absent': currentDayOfMonth};
      }

      Set<int> daysWithRecords = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final checkIn = (data['checkIn'] as Timestamp?)?.toDate();

        if (checkIn == null) continue;

        final checkInDay = checkIn.day;

        final lateThreshold =
            DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 15);

        daysWithRecords.add(checkInDay);

        counts['present'] = (counts['present'] ?? 0) + 1;

        if (checkIn.isAfter(lateThreshold)) {
          counts['late'] = (counts['late'] ?? 0) + 1;
        }
      }

      for (int day = 1; day <= currentDayOfMonth; day++) {
        final DateTime date = DateTime(now.year, now.month, day);

        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          continue;
        }

        if (!daysWithRecords.contains(day)) {
          counts['absent'] = (counts['absent'] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      log('Error fetching monthly attendance: $e');
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
    if (index == 1) const StatsticsScreen();
    if (index == 2) ProfileScreen;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
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
                  color: isSelected
                      ? const Color(0xff7647EB)
                      : const Color(0xffA4A4A4),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  text,
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xff7647EB)
                          : const Color(0xffA4A4A4),
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
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AlertDialog(
                  contentPadding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.1),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Column(
                    children: [
                      Text(
                        'Are you Sure',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width *
                              0.05, // Responsive font size
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Do you want to exit the app?',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: MediaQuery.of(context).size.height * 0.05,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
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
                              width: MediaQuery.of(context).size.width *
                                  0.3, // Responsive width
                              height: MediaQuery.of(context).size.height *
                                  0.05, // Responsive height
                              decoration: BoxDecoration(
                                color: const Color(0xff7647EB),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
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
                  top: MediaQuery.of(context).size.height * 0.34,
                  child: Image.asset(
                    'assets/warning_alert.png',
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.15,
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
              ? const StatsticsScreen()
              : _selectedIndex == 2
                  ? const ProfileScreen()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 16.0),
                      child: Column(
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(user?.uid)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return Row(children: [
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationScreen()),
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
                                    userData['name'] ?? ".";
                                String email =
                                    userData['email'] ?? ".";

                                return Row(children: [
                                  if (_imageUrl != null &&
                                      _imageUrl!.isNotEmpty)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
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
                                ]);
                              }),
                          const SizedBox(height: 30),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffEFF1FF),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Padding(
                                  padding: EdgeInsets.only(left: 25.0),
                                  child: Text(
                                    'Monthly Attendance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      height: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FutureBuilder<Map<String, int>>(
                                  future: fetchMonthlyAttendance(user!.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }

                                    if (snapshot.hasData) {
                                      final data = snapshot.data!;

                                      if (data['present'] == 0 &&
                                          data['late'] == 0 &&
                                          data['absent'] == 0) {
                                        return const Center(
                                          child: Text(
                                              'No attendance records available for this month.'),
                                        );
                                      }
                                      //Monthly attendance componenet

                                      return Monthlyattendance(
                                        presentCount: data['present']!,
                                        lateCount: data['late']!,
                                        absentCount: data['absent']!,
                                      );
                                    }

                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xffEFF1FF),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
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
                                      availableGestures:
                                          AvailableGestures.horizontalSwipe,
                                      headerVisible: true,
                                      selectedDayPredicate: (day) =>
                                          isSameDay(_selectedDay, day),
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
                                      eventLoader: _getEventsForDay,
                                      calendarBuilders: CalendarBuilders(
                                        markerBuilder: (context, day, events) {
                                          // Get the currently visible month in the calendar.
                                          final currentMonth =
                                              DateTime.now().month;
                                          final currentYear =
                                              DateTime.now().year;

                                          // Check if the day is within the current month and year.
                                          bool isCurrentMonth =
                                              (day.month == currentMonth &&
                                                  day.year == currentYear);

                                          // Check if the day is a weekend (Saturday or Sunday).
                                          bool isWeekend = day.weekday ==
                                                  DateTime.saturday ||
                                              day.weekday == DateTime.sunday;

                                          // Ensure markers are only shown for past or present days within the current month.
                                          bool isPastOrToday =
                                              day.isBefore(DateTime.now()) ||
                                                  day.isAtSameMomentAs(
                                                      DateTime.now());

                                          // Determine the event color (red for missing check-ins, event color otherwise).
                                          Color? eventColor = (!isWeekend &&
                                                  isCurrentMonth &&
                                                  isPastOrToday)
                                              ? (events.isEmpty
                                                  ? const Color(0xffEC5851)
                                                  : events.first as Color)
                                              : null; // No marker for weekends, future dates, or non-current months.

                                          // Return the marker only if there's a valid color (i.e., not null).
                                          if (eventColor != null) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 1.5),
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: eventColor,
                                              ),
                                            );
                                          }

                                          // Return an empty widget if no marker is needed.
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _isLoading
                                      ? const CircularProgressIndicator()
                                      : Container(
                                          height: 142,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: const Color(0xffEFF1FF),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(4, 4),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Attendance Details',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Builder(
                                                      builder: (context) {
                                                        if (data == null) {
                                                          return DailyEmptyAttendance(
                                                            selectedDay:
                                                                _selectedDay,
                                                          );
                                                        }

                                                        // Show the fetched attendance data
                                                        return DailyAttendance(
                                                          data: data!,
                                                          selectedDay:
                                                              _selectedDay,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
        floatingActionButton: _selectedIndex == 0
            ? FutureBuilder<Map<String, dynamic>?>(
                future: _getAttendanceDetails(userId, DateTime.now()),
                builder: (context, snapshot) {
                  DateTime? checkIn;
                  DateTime? checkOut;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    checkIn = (data['checkIn'] as Timestamp?)?.toDate();
                    checkOut = (data['checkOut'] as Timestamp?)?.toDate();
                  }

                  if (checkIn != null && checkOut == null) {
                    // Display Check-Out Button
                    return DraggableFab(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Circle
                            Material(
                              elevation: 4.0, // Adjust elevation as needed
                              shape: const CircleBorder(),
                              child: CircleAvatar(
                                radius:
                                    45, // This defines the size of the CircleAvatar (90 width and height)
                                backgroundColor: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xffFB3F4A),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Middle Circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xffFB3F4A),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            FloatingActionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckinScreen(),
                                  ),
                                );
                              },
                              backgroundColor: const Color(0xffffd7d9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    300), // Set border radius
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/mingcute.png',
                                    height: 20,
                                    width: 20,
                                    color: const Color(0xffFB3F4A),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Check Out',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 8,
                                      height: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (checkIn == null && checkOut == null) {
                    // Display Check-In Button
                    return DraggableFab(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Circle
                            Material(
                              elevation: 4.0, // Adjust elevation as needed
                              shape: const CircleBorder(),
                              child: CircleAvatar(
                                radius:
                                    45, // This defines the size of the CircleAvatar (90 width and height)
                                backgroundColor: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xff8E71DF),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Middle Circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff8E71DF),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            FloatingActionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckinScreen(),
                                  ),
                                );
                              },
                              backgroundColor: const Color(0xffEFF1FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    300), // Set border radius
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/mingcute.png',
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Check In',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 8,
                                      height: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Container(
            height: 65,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: const Color(0xffEFF1FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2), // changes position of shadow
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSegmentNavigator('Home', 0, const Icon(Icons.home)),
                _buildSegmentNavigator(
                    'Stats', 1, const Icon(Icons.graphic_eq_outlined)),
                _buildSegmentNavigator('Profile', 2, const Icon(Icons.person)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
