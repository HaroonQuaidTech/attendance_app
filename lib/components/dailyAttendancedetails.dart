// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, file_names, depend_on_referenced_packages, unnecessary_string_interpolations, unused_local_variable, unused_element


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyAttendance extends StatefulWidget {
  final Map<String, dynamic>? data;
  final DateTime? selectedDay;
  const DailyAttendance({Key? key, required this.data, required this.selectedDay}) : super(key: key);

  @override
  State<DailyAttendance> createState() => _DailyAttendanceState();
}

class _DailyAttendanceState extends State<DailyAttendance> {

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Null';
    final DateFormat formatter =
        DateFormat('hh:mm a'); // Format to display only time
    return formatter.format(dateTime);
  }

  String _calculateTotalHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) {
      return "N/A";
    }

    Duration duration = checkOut.difference(checkIn);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    final String formattedHours = hours.toString().padLeft(2, '0');
    final String formattedMinutes = minutes.toString().padLeft(2, '0');

    return '$formattedHours:$formattedMinutes';
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    DateTime now = DateTime.now();

    // Access the data passed to this screen
    final data = widget.data;
  
    DateTime? checkInTime = (data?['checkIn'] != null)
        ? (data!['checkIn'] as Timestamp).toDate()
        : null;
    DateTime? checkOutTime = (data?['checkOut'] != null)
        ? (data!['checkOut'] as Timestamp).toDate()
        : null;

    // Format check-in and check-out times
    String checkInTimeFormatted =
        checkInTime != null ? DateFormat('hh:mm a').format(checkInTime) : 'N/A';
    String checkOutTimeFormatted = checkOutTime != null
        ? DateFormat('hh:mm a').format(checkOutTime)
        : 'N/A';

    // Calculate total hours
    final totalHours = _calculateTotalHours(checkInTime, checkOutTime);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: screenHeight * 0.1,
      width: screenWidth * 0.90,
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
                    color: Color(0xff8E71DF),
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(widget.selectedDay!),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      DateFormat('EEE').format(widget.selectedDay!),
                      style: TextStyle(
                          fontSize: 14,
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
                checkInTimeFormatted,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              Text(
                'Check In',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
                checkOutTimeFormatted,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              Text(
                'Check Out',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
                '$totalHours',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              Text(
                'Total Hrs',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ],
          )
        ],
      ),
    );
  }
}
