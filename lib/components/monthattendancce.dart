// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, unnecessary_string_interpolations, unused_element, depend_on_referenced_packages, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
enum AttendanceType { monthly}
class MonthlyAttendance extends StatefulWidget {
  final Color color;
  final String? dropdownValue2;
   final AttendanceType attendanceType;

  const MonthlyAttendance({
    Key? key,
    required this.color,
    required this.dropdownValue2,
     this.attendanceType = AttendanceType.monthly,
  }) : super(key: key);

  @override
  State<MonthlyAttendance> createState() => _MonthlyAttendanceState();
}

class _MonthlyAttendanceState extends State<MonthlyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;

  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> lateArrivals = [];
  List<Map<String, dynamic>> absents = [];
  List<Map<String, dynamic>> onTime = [];
  List<Map<String, dynamic>> earlyOuts = [];
  List<Map<String, dynamic>> presents = [];
  Future<void> _getMonthlyAttendance(String uid) async {
    DateTime today = DateTime.now();

    // Get the first day of the current month
    DateTime firstDayOfMonth = DateTime(today.year, today.month, 1);

    // Get the last day of the current month
    int lastDayOfMonth = DateTime(today.year, today.month + 1, 0)
        .day; // This gets the last day of the current month

    for (int day = 1; day <= lastDayOfMonth; day++) {
      DateTime currentDate =
          DateTime(firstDayOfMonth.year, firstDayOfMonth.month, day);
      String formattedDate = DateFormat('yMMMd').format(currentDate);
      String formattedDay = DateFormat('EEE').format(currentDate);

      // Fetch attendance data from Firestore for the current date
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('AttendanceDetails')
              .doc(uid)
              .collection('dailyattendance')
              .doc(formattedDate)
              .get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data();

        if (data != null) {
          DateTime? checkInTime = (data['checkIn'] as Timestamp?)?.toDate();
          DateTime? checkOutTime = (data['checkOut'] as Timestamp?)?.toDate();

          List<String> statuses = [];

          if (checkInTime == null) {
            statuses.add("Absent");
            absents.add(data);
          } else {
            // Late Arrival condition
            if (checkInTime.isAfter(DateTime(
                currentDate.year, currentDate.month, currentDate.day, 8, 15))) {
              statuses.add("Late Arrival");
              lateArrivals.add(data);
            }

            // Early Out condition
            if (checkOutTime != null &&
                checkOutTime.isBefore(DateTime(currentDate.year,
                    currentDate.month, currentDate.day, 17, 0))) {
              statuses.add("Early Out");
              earlyOuts.add(data);
            }

            // On Time condition
            if (checkInTime.isAfter(DateTime(currentDate.year,
                    currentDate.month, currentDate.day, 7, 50)) &&
                checkInTime.isBefore(DateTime(currentDate.year,
                    currentDate.month, currentDate.day, 8, 10))) {
              statuses.add("On Time");
              onTime.add(data);
            }
          }

          // Add additional data to each entry
          data['formattedDate'] = formattedDate;
          data['formattedDay'] = formattedDay;
          data['statuses'] = statuses;
          monthlyData.add(data);
        } else {
          // No data for this day, mark as Absent
          monthlyData.add({
            "checkIn": null,
            "checkOut": null,
            "statuses": ["Absent"],
            "formattedDate": formattedDate,
            "formattedDay": formattedDay,
          });
        }
      }
    }

    // Update UI state
    setState(() {
      isLoading = false;
    });
  }

  String _calculateTotalHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return '0:00';

    DateTime checkInTime = checkIn.toDate();
    DateTime checkOutTime = checkOut.toDate();

    Duration duration = checkOutTime.difference(checkInTime);

    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "--:--";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  void initState() {
    super.initState();
    _getMonthlyAttendance(userId);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredData = widget.dropdownValue2 == 'Select'
        ? monthlyData
        : widget.dropdownValue2 == 'On Time'
            ? monthlyData
                .where((element) =>
                    (element['statuses'] as List).contains('On Time'))
                .toList()
            : widget.dropdownValue2 == 'Absent'
                ? monthlyData
                    .where((element) =>
                        (element['statuses'] as List).contains('Absent'))
                    .toList()
                : widget.dropdownValue2 == 'Early Out'
                    ? monthlyData
                        .where((element) =>
                            (element['statuses'] as List).contains('Early Out'))
                        .toList()
                    : widget.dropdownValue2 == 'Late Arrival'
                        ? monthlyData
                            .where((element) => (element['statuses'] as List)
                                .contains('Late Arrival'))
                            .toList()
                        : monthlyData;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  Map<String, dynamic> data = filteredData[index];
                  final DateTime date = DateFormat('MMM dd, yyyy')
                      .parse(filteredData[index]['formattedDate']);
                  final String day = DateFormat('EE').format(date);

                  // Skip weekends (Saturday and Sunday)
                  if (day == 'Sat' || day == 'Sun') {
                    return SizedBox
                        .shrink(); // Return an empty widget for weekends
                  }

                  final String formattedDate = DateFormat('dd').format(date);
                  String checkInTime =
                      _formatTime(data['checkIn'] as Timestamp?);
                  String checkOutTime =
                      _formatTime(data['checkOut'] as Timestamp?);
                  String totalHours = _calculateTotalHours(
                      data['checkIn'] as Timestamp?,
                      data['checkOut'] as Timestamp?);

                  String status = "On Time";

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
                                color: status == "Late"
                                    ? Colors.orange
                                    : status == "Absent"
                                        ? Colors.red
                                        : Colors
                                            .green, // Custom color based on status
                              ),
                            ),
                            Text(
                              'Total Hours',
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
