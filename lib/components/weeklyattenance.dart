// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, unnecessary_string_interpolations, unused_element, depend_on_referenced_packages, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class WeeklyAttendance extends StatefulWidget {
  final Color color;


  const WeeklyAttendance({
    Key? key,
    required this.color,
      
  }) : super(key: key);

  @override
  State<WeeklyAttendance> createState() => _WeeklyAttendanceState();
}

class _WeeklyAttendanceState extends State<WeeklyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> weeklyData = [];
  Future<void> _getWeeklyAttendance(String uid) async {
    DateTime today = DateTime.now();
    DateTime startOfWeek = today
        .subtract(Duration(days: today.weekday - 1)); // Get Monday of this week
    // Get Sunday of this week

    // Loop through the days of the week
    for (int i = 0; i < 5; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yMMMd').format(day);
      String formattedDay = DateFormat('EEE').format(day); // Format the day

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('AttendanceDetails')
              .doc(userId)
              .collection('dailyattendance')
              .doc(formattedDate)
              .get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data();
        if (data != null) {
          weeklyData.add(data);
          data['formattedDate'] = formattedDate;
          data['formattedDay'] = formattedDay;
        } else {
          // If no data for the day, add a default leave status
          weeklyData.add({
            "checkIn": null,
            "checkOut": null,
            "status": "Leave",
            "formattedDate": formattedDate,
            "formattedDay": formattedDay,
          });
        }
      } else {
        // If no data for the day, add a default leave status
        weeklyData.add({
          "checkIn": null,
          "checkOut": null,
          "status": "Leave",
        });
      }
    }
    setState(() {});
  }

  String _calculateTotalHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null)
      return '0:00'; // No hours if either is null

    DateTime checkInTime = checkIn.toDate();
    DateTime checkOutTime = checkOut.toDate();

    Duration duration = checkOutTime.difference(checkInTime);

    // Format total hours and minutes
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60; // Get remaining minutes

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'; // Format as HH:mm
  }

  String _getAttendanceStatus(Map<String, dynamic> data) {
    if (data['checkIn'] == null) {
      return "Leave";
    }
    DateTime checkInTime = (data['checkIn'] as Timestamp).toDate();
    DateTime checkOutTime = data['checkOut'] != null
        ? (data['checkOut'] as Timestamp).toDate()
        : DateTime.now();

    if (checkInTime.isAfter(DateTime(
        checkInTime.year, checkInTime.month, checkInTime.day, 8, 30))) {
      return "Late Arrival"; // Late if after 8:30 AM
    } else if (checkOutTime.isBefore(DateTime(
        checkOutTime.year, checkOutTime.month, checkOutTime.day, 17, 0))) {
      return "Early Out"; // Early if before 5:00 PM
    } else {
      return "On Time";
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "--:--";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime); // Format as 'HH:mm AM/PM'
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date); // Format as 'Day, Month Day'
  }

  @override
  void initState() {
    super.initState();
    _getWeeklyAttendance(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: weeklyData.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> data = weeklyData[index];
                _getAttendanceStatus(data);
                final DateTime date = DateTime.now().subtract(
                    Duration(days: DateTime.now().weekday - 1 - index));
                final String day = DateFormat('EE').format(date);
                final String formattedDate = DateFormat('dd').format(date);

                String checkInTime = _formatTime(data['checkIn'] as Timestamp?);
                String checkOutTime =
                    _formatTime(data['checkOut'] as Timestamp?);
                String totalHours = _calculateTotalHours(
                    data['checkIn'] as Timestamp?,
                    data['checkOut'] as Timestamp?);

                return Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 10),
                  height: 82,
                  width: double.infinity,
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
                              color: widget.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
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
                            checkInTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Check In',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.black),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            checkOutTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Check Out',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        decoration: BoxDecoration(color: Colors.black),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalHours,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Total Hrs',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
        ),
      ],
    );
  }
}
