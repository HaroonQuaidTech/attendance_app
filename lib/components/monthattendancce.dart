// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, unnecessary_string_interpolations, unused_element, depend_on_referenced_packages, curly_braces_in_flow_control_structures



import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class   MonthlyAttendance extends StatefulWidget {
  final Color color;
   final  String? dropdownValue2 ;



  const MonthlyAttendance({
    Key? key,
    required this.color,
    required this.dropdownValue2,

      
  }) : super(key: key);

  @override
  State<MonthlyAttendance> createState() => _WeeklyAttendanceState();
}

class _WeeklyAttendanceState extends State<MonthlyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;

List<Map<String, dynamic>> monthlyData = [];
List<Map<String, dynamic>> lateArrivals = [];
List<Map<String, dynamic>> absents = [];
List<Map<String, dynamic>> onTime = [];
List<Map<String, dynamic>> earlyOuts = [];
List<Map<String, dynamic>> presents = [];
Future<void> _getMonthlyAttendance(String uid) async {
  setState(() {
    isLoading = true;
  });
  DateTime today = DateTime.now();
  DateTime startOfMonth = DateTime(today.year, today.month, 1);
  DateTime endOfMonth = DateTime(today.year, today.month + 1, 1).subtract(Duration(days: 1));

  for (int i = 0; i <= endOfMonth.difference(startOfMonth).inDays; i++) {
    DateTime day = startOfMonth.add(Duration(days: i));
    String formattedDate = DateFormat('yMMMd').format(day);
    String formattedDay = DateFormat('EEE').format(day);

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('AttendanceDetails')
        .doc(uid)
        .collection('dailyattendance')
        .doc(formattedDate)
        .get();

if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data();
      
      // Debugging: Print document ID and data
    

      if (data != null) {
        log("if condition");
        // Safely check if checkIn and checkOut exist and are timestamps
        DateTime? checkInTime = (data['checkIn'] as Timestamp?)?.toDate();
        DateTime? checkOutTime = (data['checkOut'] as Timestamp?)?.toDate();

        String status;
      
     if (checkInTime == null) {
  status = "Absent";
  absents.add(data);
} else {
  if (checkInTime.isAfter(DateTime(day.year, day.month, day.day, 8, 30))) {
    status = "Late";
    lateArrivals.add(data);
  } else {
    status = "On Time";
    onTime.add(data);
  }

  if (checkOutTime != null && checkOutTime.isBefore(DateTime(day.year, day.month, day.day, 17, 0))) { //5 pm-- 24 hours formaat
    status = "Early Out";
    earlyOuts.add(data);
  } else {
    // If the user is on time and checked out correctly, mark them as present
    status = "Present";
    presents.add(data);
  }
}
        log('---------status----------------------------$status');

        // Add extra details to the data object
        data['formattedDate'] = formattedDate;
        data['formattedDay'] = formattedDay;
        data['status'] = status;
        monthlyData.add(data);
      } else {
        // Handle case where data is null but snapshot exists
        log("Data is null for document: $formattedDate");
         log("-------------------------------else condition");
        monthlyData.add({
          "checkIn": null,
          "checkOut": null,
          "status": "Leave",
          "formattedDate": formattedDate,
          "formattedDay": formattedDay,
        });
      }
    } else {
      // Handle case where document does not exist
      monthlyData.add({
        "checkIn": null,
        "checkOut": null,
        "status": "Leave",
        "formattedDate": formattedDate,
        "formattedDay": formattedDay,
      });
    }
  }

  setState(() {
    isLoading = false;
  });
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
    _getMonthlyAttendance(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
            if (isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )else

        Flexible(
          fit: FlexFit.loose,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.dropdownValue2=='Select' ? monthlyData.length:
               widget.dropdownValue2=='On Time'?monthlyData.where((element) => element['status'] == 'On Time').toList().length :
                widget.dropdownValue2=='Absent'?monthlyData.where((element) => element['status'] == 'Absent').toList().length :
                 widget.dropdownValue2=='Early Out'?monthlyData.where((element) => element['status'] == 'Early Out').toList().length :
                  widget.dropdownValue2=='Late Arrival'?monthlyData.where((element) => element['status'] == 'Late Arrival').toList().length :
                  monthlyData.length,
              itemBuilder: (context, index) {
                log(monthlyData[index]['status']);
                Map<String, dynamic> data = monthlyData[index];
                final DateTime now = DateTime.now();

  
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    final DateTime date = firstDayOfMonth.add(Duration(days: index));

   
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    
         
              // Fetch checkIn and checkOut times
              String checkInTime = _formatTime(data['checkIn'] as Timestamp?);
              String checkOutTime = _formatTime(data['checkOut'] as Timestamp?);
              String totalHours = _calculateTotalHours(data['checkIn'] as Timestamp?, data['checkOut'] as Timestamp?);

              // Filter and determine attendance status
              String status = "On Time"; // Default status
           
 
                

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
                                     color: status == "Late" ? Colors.orange : status == "Absent" ? Colors.red : Colors.green, // Custom color based on status

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
