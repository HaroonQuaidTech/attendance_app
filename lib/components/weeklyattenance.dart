import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyAttendance extends StatefulWidget {
  final Color color;
  final String filter;

  const WeeklyAttendance({
    super.key,
    required this.color,
    required this.filter,
  });

  @override
  State<WeeklyAttendance> createState() => _WeeklyAttendanceState();
}

class _WeeklyAttendanceState extends State<WeeklyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> weeklyData = [];

  Future<void> _getWeeklyAttendance(String uid) async {
    DateTime today = DateTime.now();
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (int i = 0; i < 5; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yMMMd').format(day);
      // String formattedDay = DateFormat('EEE').format(day);

      try {
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
            data['formattedDate'] = formattedDate;
            // Only add data if it matches the filter
            if (_isDataMatchingFilter(data)) {
              weeklyData.add(data);
            }
          }
        } else {
          // If no data for the day, add a default leave status if it matches the filter
          if (widget.filter == "Leave") {
            weeklyData.add({
              "checkIn": null,
              "checkOut": null,
              "status": "Leave",
              "formattedDate": formattedDate,
            });
          }
        }
      } catch (e) {
        // Handle error if necessary
      }
    }
    setState(() {});
  }

  bool _isDataMatchingFilter(Map<String, dynamic> data) {
    switch (widget.filter) {
      case "Present":
        return data['checkIn'] != null; // Present if check-in is available
      case "Leave":
        return data['checkIn'] == null; // Leave if check-in is null
      case "Late Arrival":
        DateTime checkInTime = (data['checkIn'] as Timestamp).toDate();
        return checkInTime.isAfter(DateTime(
            checkInTime.year, checkInTime.month, checkInTime.day, 8, 30));
      case "Early Out":
        DateTime checkOutTime = data['checkOut'] != null
            ? (data['checkOut'] as Timestamp).toDate()
            : DateTime.now();
        return checkOutTime.isBefore(DateTime(
            checkOutTime.year, checkOutTime.month, checkOutTime.day, 17, 0));
      default:
        return true; // Show all if filter is not recognized
    }
  }

  String _calculateTotalHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) {
      return '0:00'; // No hours if either is null
    }

    DateTime checkInTime = checkIn.toDate();
    DateTime checkOutTime = checkOut.toDate();

    Duration duration = checkOutTime.difference(checkInTime);

    // Format total hours and minutes
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60; // Get remaining minutes

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'; // Format as HH:mm
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "--:--";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime); // Format as 'HH:mm AM/PM'
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
                final DateTime date = DateTime.now().subtract(
                    Duration(days: DateTime.now().weekday - 2 - index));
                final String formattedDate = DateFormat('dd').format(date);
                final String day = DateFormat('EE').format(date);

                final String checkInTime =
                    _formatTime(data['checkIn'] as Timestamp?);
                final String checkOutTime =
                    _formatTime(data['checkOut'] as Timestamp?);
                final String totalHours = _calculateTotalHours(
                    data['checkIn'] as Timestamp?,
                    data['checkOut'] as Timestamp?);

                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
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
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            checkInTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
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
                        decoration: const BoxDecoration(color: Colors.black),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            checkOutTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
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
                        decoration: const BoxDecoration(color: Colors.black),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalHours,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Text(
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
