// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, unused_local_variable, unnecessary_string_interpolations, depend_on_referenced_packages, unnecessary_null_comparison, prefer_const_declarations, unnecessary_brace_in_string_interps, unused_element

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StatusBuiler extends StatefulWidget {
  const StatusBuiler({
    Key? key,
  }) : super(key: key);

  @override
  State<StatusBuiler> createState() => _StatusBuilerState();
}

class _StatusBuilerState extends State<StatusBuiler> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Future<List<Map<String, dynamic>?>> _getMonthlyAttendanceDetails(
      String uid) async {
    List<Map<String, dynamic>?> monthlyAttendanceList = [];

    final now = DateTime.now();

    // Get the first and last day of the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Loop through each day of the current month
    for (int i = 0;
        i <= lastDayOfMonth.difference(firstDayOfMonth).inDays;
        i++) {
      final date = firstDayOfMonth.add(Duration(days: i));

      // Skip weekends (Saturdays and Sundays)

      final formattedDate = DateFormat('yMMMd').format(date);

      // Fetch attendance data for the day

      // Fetch attendance data for the day
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('AttendanceDetails')
              .doc(uid)
              .collection('dailyattendance')
              .doc(formattedDate)
              .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        // Check if the user has checked in, if not mark it as empty attendance
        final checkIn = (data?['checkIn'] as Timestamp?)?.toDate();
        if (checkIn == null) {
          monthlyAttendanceList.add({
            'date': formattedDate,
            'status': 'Absent', // or handle it as you need
          });
        } else {
          // If check-in exists, add the attendance data
          monthlyAttendanceList.add(data);
        }
      } else {
        // If no data exists for the day, mark it as absent (or empty)
        monthlyAttendanceList.add({
          'date': formattedDate,
          'status': 'Absent', // Handle missing attendance as 'Absent'
        });
      }
    }

    return monthlyAttendanceList;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not Available';
    final DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  String _calculateTotalHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) {
      return "Null";
    }

    Duration duration = checkOut.difference(checkIn);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    final String formattedHours = hours.toString().padLeft(2, '0');
    final String formattedMinutes = minutes.toString().padLeft(2, '0');

    return '$formattedHours:$formattedMinutes';
  }

  int _calculateWeeklyTotal(List<Map<String, dynamic>?> weeklyData) {
    int totalMinutes = 0;

    for (var data in weeklyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        totalMinutes += duration.inMinutes;
      }
    }

    return totalMinutes;
  }

  int _calculateWeeklyTotalP(List<Map<String, dynamic>?> weeklyData) {
    int totalMinutes = 0;

    for (var data in weeklyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        totalMinutes += duration.inMinutes;
      }
    }

    return totalMinutes;
  }

  double _calculateWeeklyHours(List<Map<String, dynamic>?> weeklyData) {
    int totalMinutes = 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    for (var data in weeklyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final date = checkIn.toLocal();
        if (date.isAfter(startOfWeek) && date.isBefore(endOfWeek)) {
          final duration = checkOut.difference(checkIn);
          totalMinutes += duration.inMinutes;
        }
      }
    }

    return totalMinutes / 60;
  }

//-------------------------1
  Widget _buildEmptyAttendanceContainer(
    int index,
  ) {
    final DateTime now = DateTime.now();

    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    final DateTime date = firstDayOfMonth.add(Duration(days: index));

    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 10),
      height: 82,
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 53,
                height: 55,
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      day,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Text(
              'Leave/Day off',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHNullAttendanceContainer(
    int index,
  ) {
    final DateTime now = DateTime.now();

    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    final DateTime date = firstDayOfMonth.add(Duration(days: index));

    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 10),
      height: 82,
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 53,
                height: 55,
                decoration: BoxDecoration(
                    color: Color(0xff8E71DF),
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      day,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Text(
              'Data not Available',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  String getCurrentMonthDateRange() {
    final now = DateTime.now();

    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Format the dates
    final formattedFirstDay = DateFormat('dd MMM').format(firstDayOfMonth);
    final formattedLastDay = DateFormat('dd MMM').format(lastDayOfMonth);

    return '$formattedFirstDay - $formattedLastDay';
  }

  Future<void> _refresh() {
    return Future.delayed(Duration(seconds: 1));
  }

  Widget _buildAttendance({
    required Color color,
  }) {
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: _getMonthlyAttendanceDetails(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Center(
                child: Text('No attendance data found.',
                    style: TextStyle(fontSize: 20))),
          );
        }

        final data = snapshot.data!;
        final weeklyData = snapshot.data!;
        Color containerColor;

        final totalTime = _calculateWeeklyTotal(weeklyData);
        final totalHours = (totalTime / 60).toStringAsFixed(2);
        final totalMinutes = _calculateWeeklyTotal(weeklyData);
        final totalHourss = _calculateWeeklyHours(weeklyData);

        final int maxMinutes = 3000;
        final double maxHours = 40;

        final double progress = totalHourss / maxHours;

        final double progresss = totalMinutes / maxMinutes;

        final now = DateTime.now();

        final attendanceData = snapshot.data!;
//--------------------------------------------list view builder---------------------------------------------------------------------------------
        return Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: attendanceData.length,
              itemBuilder: (context, index) {
                final data = attendanceData[index];

                if (data == null) {
                  return _buildHNullAttendanceContainer(index);
                }

                final DateTime now = DateTime.now();

                final DateTime firstDayOfMonth =
                    DateTime(now.year, now.month, 1);

                final DateTime date =
                    firstDayOfMonth.add(Duration(days: index));

                final String day = DateFormat('EE').format(date);
                final String formattedDate = DateFormat('dd').format(date);
                if (date.isAfter(now)) {
                
                  return _buildHNullAttendanceContainer(
                      index); 
                }
                if (date.weekday == DateTime.saturday ||
                    date.weekday == DateTime.sunday) {
                  return _buildHNullAttendanceContainer(
                      index); 
                }

             
                if (data == null) {
                  return _buildHNullAttendanceContainer(
                      index); 
                }

              
                final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
                final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

              
                if (checkIn == null && checkOut == null) {
                  return _buildEmptyAttendanceContainer(
                      index);
                }

                final totalHours = _calculateTotalHours(checkIn, checkOut);
                Color containerColor;

                if (checkIn != null) {
                  final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
                  final TimeOfDay onTime = TimeOfDay(hour: 8, minute: 0);
                  final TimeOfDay lateArrival = TimeOfDay(hour: 8, minute: 15);

                  final DateTime today = DateTime.now();
                  final DateTime checkInDateTime = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    checkInTime.hour,
                    checkInTime.minute,
                  );
                  final DateTime onTimeDateTime = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    onTime.hour,
                    onTime.minute,
                  );
                  final DateTime lateArrivalDateTime = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    lateArrival.hour,
                    lateArrival.minute,
                  );

                  if (checkInDateTime.isBefore(onTimeDateTime)) {
                    containerColor = Color(0xff22AF41);
                  } else if (checkInDateTime.isAfter(lateArrivalDateTime)) {
                    containerColor = Color(0xffF6C15B);
                  } else {
                    containerColor = Color(0xffEC5851);
                  }
                } else {
                  containerColor = Color(0xff8E71DF);
                }

                if (checkOut != null) {
                  final TimeOfDay checkOutTime =
                      TimeOfDay.fromDateTime(checkOut);
                  final TimeOfDay earlyCheckout =
                      TimeOfDay(hour: 17, minute: 0);

                  final DateTime today = DateTime.now();
                  final DateTime checkOutDateTime = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    checkOutTime.hour,
                    checkOutTime.minute,
                  );
                  final DateTime earlyCheckoutDateTime = DateTime(
                    today.year,
                    today.month,
                    today.day,
                    earlyCheckout.hour,
                    earlyCheckout.minute,
                  );

                  if (checkOutDateTime.isBefore(earlyCheckoutDateTime)) {
                    containerColor = Color(0xffF07E25); // Early check-out
                  }
                }

                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 10),
                  height: 82,
                  width: 360,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 53,
                            height: 55,
                            decoration: BoxDecoration(
                                color: containerColor,
                                borderRadius: BorderRadius.circular(6)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                Text(
                                  day,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            checkIn != null ? _formatTime(checkIn) : 'N/A',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black),
                          ),
                          Text(
                            'Check In',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.black,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            checkOut != null ? _formatTime(checkOut) : 'N/A',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black),
                          ),
                          Text(
                            'Check Out',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.black,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalHours != null ? '$totalHours' : 'N/A',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black),
                          ),
                          Text(
                            'Total Hrs',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final String startFormatted = DateFormat('dd MMM').format(startOfWeek);
    final String endFormatted = DateFormat('dd MMM').format(endOfWeek);
    final DateTime previousWeekStart = DateTime(now.year, 9, 2);
    final DateTime previousWeekEnd = DateTime(now.year, 9, 6);
    final DateTime newWeekStart = DateTime(now.year, 9, 9);
    final DateTime newWeekEnd = DateTime(now.year, 9, 13);

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(children: [
        FutureBuilder(
            future: _getMonthlyAttendanceDetails(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('No data available'));
              }
              final List<Map<String, dynamic>?> allData = snapshot.data ?? [];

              final List<Map<String, dynamic>?> newWeekData =
                  allData.where((data) {
                final dateStr = data?['date'] as String?;
                if (dateStr == null) return false;
                final DateTime date =
                    DateTime.tryParse(dateStr) ?? DateTime.now();
                return date.isAfter(newWeekStart.subtract(Duration(days: 1))) &&
                    date.isBefore(newWeekEnd.add(Duration(days: 1)));
              }).toList();

              final weeklyData = snapshot.data!;

              final totalTime = _calculateWeeklyTotal(weeklyData);

              final totalHours = (totalTime / 60).toStringAsFixed(2);
              final totalMinutes = _calculateWeeklyTotal(weeklyData);
              final totalHourss = _calculateWeeklyHours(weeklyData);

              final int maxMinutes = 3000;
              final double maxHours = 40;

              final double progress = totalHourss / maxHours;

              final double progresss = totalMinutes / maxMinutes;

              return SingleChildScrollView(
                child: Container(
                    height: 207,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xffEFF1FF),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Times Log',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 18),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: screenHeight * 0.15,
                                    width: screenWidth * 0.43,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Time in mints',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            '$totalTime Mints',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20),
                                          ),
                                          LinearProgressIndicator(
                                            value: totalMinutes / maxMinutes,
                                            backgroundColor: Colors.grey[300],
                                            color: Color(0xff9478F7),
                                          ),
                                          Text(
                                            '${getCurrentMonthDateRange()}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: screenHeight * 0.15,
                                    width: screenWidth * 0.43,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Time in hours',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            '$totalHours hours',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20),
                                          ),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey[300],
                                            color: Color(0xff9478F7),
                                          ),
                                          Text(
                                            '${getCurrentMonthDateRange()}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14),
                            ]))),
              );
            }),
        SizedBox(
          height: 20,
        ),
        Container(
            padding: EdgeInsets.all(12),
            height: 530,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Attendance: ${getCurrentMonthDateRange()}',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                SizedBox(
                  height: 10,
                ),
                _buildAttendance(color: Color(0xff9478F7)),
                SizedBox(
                  height: 10,
                ),
              ],
            )),
      ]),
    );
  }
}
