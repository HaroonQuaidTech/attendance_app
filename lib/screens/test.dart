import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/components/dailyAttendancedetails.dart';
import 'package:quaidtech/components/dailyNullAttend.dart';
import 'package:table_calendar/table_calendar.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  Map<String, dynamic>? data;
  List<Map<String, dynamic>> weeklyData = [];

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
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
            // final checkOut = (data['checkIn'] as Timestamp?)?.toDate();

            if (checkIn != null) {
              final lateThreshold =
                  DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 00);

              // Determine color based on attendance status
              Color eventColor;
              if (checkIn.isAfter(lateThreshold)) {
                eventColor = const Color(0xffF6C15B);
              } else if (checkIn.isBefore(lateThreshold)) {
                eventColor = const Color(0xff22AF41);
              } else {
                eventColor = const Color(0xff22AF41);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
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
                  availableGestures: AvailableGestures.horizontalSwipe,
                  headerVisible: true,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                      if (events.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(events.length, (index) {
                          final color = events[index] as Color;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Attendance Details Container
              _isLoading
                  ? const CircularProgressIndicator()
                  : Container(
                      height: 142,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Builder(
                                  builder: (context) {
                                    if (data == null) {
                                      return DailyEmptyAttendance(
                                        selectedDay: _selectedDay,
                                      );
                                    }

                                    // Show the fetched attendance data
                                    return DailyAttendance(
                                      data: data!,
                                      selectedDay: _selectedDay,
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
    );
  }
}
