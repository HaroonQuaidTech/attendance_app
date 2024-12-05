import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quaidtech/components/dailyAttendancedetails.dart';
import 'package:quaidtech/components/dailyNullAttend.dart';
import 'package:quaidtech/components/monthlyattendance.dart';
import 'package:quaidtech/main.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _imageUrl;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> weeklyData = [];
  User? user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? data;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime? _firstCheckInDate;

  final Map<DateTime, List<Color>> _events = {};

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
    log('data $data', name: 'Logg');
    DateTime? checkInTime = (data['checkIn'] != null)
        ? (data['checkIn'] as Timestamp).toDate()
        : null;
    DateTime? checkOutTime = (data['checkOut'] != null)
        ? (data['checkOut'] as Timestamp).toDate()
        : null;

    if (checkOutTime != null && checkInTime != null) {
      checkOutTime.difference(checkInTime);
    }
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
    _fetchFirstCheckInDate(userId);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isLoading = true;
    });

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

  Future<void> _fetchFirstCheckInDate(String userId) async {
    final attendanceCollection = FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(userId)
        .collection('dailyattendance');

    try {
      final querySnapshot = await attendanceCollection
          .orderBy('checkIn', descending: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
        setState(() {
          _firstCheckInDate = checkIn;
        });
        if (_firstCheckInDate != null) {
          _fetchEventsForUser(userId, _firstCheckInDate!);
        }
      }
    } catch (e) {
      log('Error fetching first check-in date: $e');
    }
  }

  Future<void> _fetchEventsForUser(String userId, DateTime startDate) async {
    final now = DateTime.now();

    final attendanceCollection = FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(userId)
        .collection('dailyattendance');

    try {
      final querySnapshot = await attendanceCollection
          .where('checkIn', isGreaterThanOrEqualTo: startDate)
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
                  DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 16);

              Color eventColor;
              if (checkIn.isAfter(lateThreshold)) {
                eventColor = StatusTheme.theme.colorScheme.primary;
              } else {
                eventColor = StatusTheme.theme.colorScheme.inversePrimary;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      int retries = 3;
      int delay = 1000;

      for (int i = 0; i < retries; i++) {
        try {
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
          return;
        } on FirebaseException catch (e) {
          if (e.code == 'unavailable' && i < retries - 1) {
            await Future.delayed(Duration(milliseconds: delay));
            delay *= 2;
          } else {
            rethrow;
          }
        }
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
        return {'present': 0, 'late': 0, 'absent': 0};
      }

      Set<int> daysWithRecords = {};
      DateTime? firstCheckInDate;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final checkIn = (data['checkIn'] as Timestamp?)?.toDate();

        if (checkIn == null) continue;

        if (firstCheckInDate == null || checkIn.isBefore(firstCheckInDate)) {
          firstCheckInDate = checkIn;
        }

        final checkInDay = checkIn.day;

        final lateThreshold =
            DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 16);

        daysWithRecords.add(checkInDay);

        counts['present'] = (counts['present'] ?? 0) + 1;

        if (checkIn.isAfter(lateThreshold)) {
          counts['late'] = (counts['late'] ?? 0) + 1;
        }
      }

      if (firstCheckInDate == null) {
        return {'present': 0, 'late': 0, 'absent': 0};
      }

      for (int day = firstCheckInDate.day; day <= currentDayOfMonth; day++) {
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
      return {
        'present': 0,
        'late': 0,
        'absent': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 16;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    double baseFontSize1 = 20;
    double responsiveFontSize1 = baseFontSize1 * (screenWidth / 375);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await showDialog(
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
                    height: screenSize.height * 0.01,
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xff3B3A3C),
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
                          'Do you want to exit app ?',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            height: 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: screenWidth * 0.3,
                                height: screenSize.height * 0.04,
                                decoration: BoxDecoration(
                                  color: const Color(0xffECECEC),
                                  borderRadius: BorderRadius.circular(10),
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
                              onTap: () {
                                exit(0);
                              },
                              child: Container(
                                width: screenWidth * 0.3,
                                height: screenSize.height * 0.04,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Continue',
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
        return exitApp;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: _selectedIndex == 1
              ? const StatsticsScreen()
              : _selectedIndex == 2
                  ? const ProfileScreen()
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 16),
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
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NotificationScreen(),
                                          ),
                                        );
                                      },
                                      child: Image.asset(
                                        'assets/notification_icon.png',
                                        height: screenSize.height * 0.04,
                                        width: screenSize.width * 0.04,
                                      ),
                                    )
                                  ]);
                                }

                                var userData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                String displayName = userData['name'] ?? ".";
                                String email = userData['email'] ?? ".";

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
                                          width: screenSize.width * 0.17,
                                          height: screenSize.height * 0.08,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: responsiveFontSize1,
                                          fontWeight: FontWeight.w600,
                                          height: 0,
                                        ),
                                      ),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: responsiveFontSize,
                                          fontWeight: FontWeight.w400,
                                          height: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationScreen(),
                                        ),
                                      );
                                    },
                                    child: Material(
                                      borderRadius: BorderRadius.circular(12),
                                      elevation: 5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
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
                                ]);
                              }),
                          const SizedBox(height: 30),
                          Material(
                            elevation: 5,
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Attendance',
                                    style: TextStyle(
                                      fontSize: responsiveFontSize,
                                      height: 0,
                                      fontWeight: FontWeight.w500,
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
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Material(
                                    elevation: 5,
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    child: Column(
                                      children: [
                                        TableCalendar(
                                          headerStyle: HeaderStyle(
                                              leftChevronIcon: Icon(
                                                Icons.chevron_left,
                                                size:
                                                    screenSize.height * 0.0275,
                                              ),
                                              rightChevronIcon: Icon(
                                                Icons.chevron_right,
                                                size:
                                                    screenSize.height * 0.0275,
                                              ),
                                              titleTextStyle: TextStyle(
                                                fontSize: responsiveFontSize,
                                              ),
                                              headerPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0)),
                                          rowHeight: screenSize.height * 0.055,
                                          daysOfWeekHeight:
                                              screenSize.height * 0.04,
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
                                          calendarStyle: CalendarStyle(
                                            todayDecoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
                                              shape: BoxShape.circle,
                                            ),
                                            todayTextStyle: const TextStyle(
                                              color: Colors.black,
                                              height: 0,
                                            ),
                                          ),
                                          calendarBuilders: CalendarBuilders(
                                            selectedBuilder:
                                                (context, date, _) {
                                              return Container(
                                                margin:
                                                    const EdgeInsets.all(8.0),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${date.day}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    height: 0,
                                                  ),
                                                ),
                                              );
                                            },
                                            markerBuilder:
                                                (context, day, events) {
                                              if (day.weekday ==
                                                      DateTime.saturday ||
                                                  day.weekday ==
                                                      DateTime.sunday) {
                                                return const SizedBox.shrink();
                                              }
                                              if (_firstCheckInDate != null &&
                                                  (day.isBefore(
                                                          _firstCheckInDate!) ||
                                                      day.isAfter(
                                                          DateTime.now()))) {
                                                return const SizedBox.shrink();
                                              }
                                              Color? eventColor =
                                                  events.isNotEmpty
                                                      ? events.first as Color
                                                      : StatusTheme
                                                          .theme
                                                          .colorScheme
                                                          .secondary;
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 1.5,
                                                ),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: eventColor,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _isLoading
                                      ? const CircularProgressIndicator()
                                      : Material(
                                          elevation: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    'Attendance Details',
                                                    style: TextStyle(
                                                      fontSize:
                                                          responsiveFontSize,
                                                      height: 0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Builder(
                                                    builder: (context) {
                                                      if (data == null) {
                                                        return DailyEmptyAttendance(
                                                          selectedDay:
                                                              _selectedDay,
                                                        );
                                                      }
                                                      return DailyAttendance(
                                                        data: data!,
                                                        selectedDay:
                                                            _selectedDay,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                  const SizedBox(height: 20),
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
                  final screenHeight = MediaQuery.of(context).size.height;

                  DateTime? checkIn;
                  DateTime? checkOut;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    checkIn = (data['checkIn'] as Timestamp?)?.toDate();
                    checkOut = (data['checkOut'] as Timestamp?)?.toDate();
                  }

                  if (checkIn != null && checkOut == null) {
                    return DraggableFab(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Material(
                              elevation: 5,
                              shape: const CircleBorder(),
                              child: CircleAvatar(
                                radius: screenHeight * 0.06,
                                backgroundColor: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/checkout_button.png',
                                    height: 20,
                                    width: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                    return DraggableFab(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Material(
                              elevation: 4.0,
                              shape: const CircleBorder(),
                              child: CircleAvatar(
                                radius: screenHeight * 0.06,
                                backgroundColor: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: screenSize.height * 0.025,
                              height: screenSize.height * 0.025,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/checkin_button.png',
                                    height: 20,
                                    width: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
            height: screenSize.height * 0.07,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: Theme.of(context).colorScheme.tertiary,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSegmentNavigator(
                    'Home',
                    0,
                    Image.asset('assets/home_selected.png'),
                    'assets/home.png',
                  ),
                  _buildSegmentNavigator(
                      'Stats',
                      1,
                      Image.asset('assets/stats_selected.png'),
                      'assets/stats.png'),
                  _buildSegmentNavigator(
                      'Profile',
                      2,
                      Image.asset('assets/profile_selected.png'),
                      'assets/profile.png'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentNavigator(
      String text, int index, Image image, String asset) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 16;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    bool isSelected = _selectedIndex == index;
    if (index == 1) const StatsticsScreen();
    if (index == 2) const ProfileScreen();
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: screenSize.height * 0.06,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(48.0),
        ),
        child: Row(
          children: [
            const SizedBox(width: 13),
            SizedBox(
              child: isSelected
                  ? Image(
                      image: image.image,
                      color: Theme.of(context).colorScheme.primary,
                      width: screenSize.height * 0.03,
                      height: screenSize.height * 0.03,
                    )
                  : Image.asset(
                      width: screenSize.height * 0.03,
                      height: screenSize.height * 0.03,
                      asset,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
            ),
            const SizedBox(
              width: 5,
            ),
            isSelected
                ? Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: responsiveFontSize,
                      height: 0,
                    ),
                  )
                : Container(),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
