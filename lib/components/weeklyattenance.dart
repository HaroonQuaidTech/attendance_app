// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, unnecessary_string_interpolations, unused_element, depend_on_referenced_packages, curly_braces_in_flow_control_structures


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyAttendance extends StatefulWidget {
  final Color color;



  const WeeklyAttendance({
    super.key,
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
        .subtract(Duration(days: today.weekday - 1)); 
  


    for (int i = 0; i < 5; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yMMMd').format(day);
      String formattedDay = DateFormat('EEE').format(day); 

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
          
          weeklyData.add({
            "checkIn": null,
            "checkOut": null,
            "status": "Leave",
            "formattedDate": formattedDate,
            "formattedDay": formattedDay,
          });
        }
      } else {
    
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
      return '0:00';

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
                    Duration(days: DateTime.now().weekday - 1 - index));
                String day = DateFormat('EE').format(date);
                String formattedDate = DateFormat('dd').format(date);
                String checkInTime = _formatTime(data['checkIn'] as Timestamp?);
                String checkOutTime =
                    _formatTime(data['checkOut'] as Timestamp?);
                String totalHours = _calculateTotalHours(
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
                        ],
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
                              height: 0,
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
