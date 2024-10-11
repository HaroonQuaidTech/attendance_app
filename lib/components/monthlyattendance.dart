// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, file_names, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

Future<Map<String, int>> fetchMonthlyAttendance(String userId) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  final attendanceCollection = FirebaseFirestore.instance
      .collection('AttendanceDetails')
      .doc(userId)
      .collection('dailyattendance');

  try {
    // Fetch attendance records for the current month up to the current date
    final querySnapshot = await attendanceCollection
        .where('checkIn', isGreaterThanOrEqualTo: startOfMonth)
        .where('checkIn',
            isLessThanOrEqualTo: now) // Only consider past and current dates
        .get();

    // Get the current day of the month (this ensures we don't count future absences)
    final currentDayOfMonth = now.day;

    // If there are no records for the month, assume all days up to today are absences
    if (querySnapshot.docs.isEmpty) {
      return {'present': 0, 'late': 0, 'absent': currentDayOfMonth};
    }

    // Define late arrival threshold (8:15 AM)
    final lateThreshold = DateTime(now.year, now.month, now.day, 8, 15);

    // Initialize attendance counters
    Map<String, int> counts = {
      'present': 0,
      'late': 0,
      'absent': 0,
    };

    // Set of all days in the month with attendance records
    Set<int> daysWithRecords = {};

    // Process each attendance record
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)
          ?.toDate(); // Check for checkOut as well

      // If both check-in and check-out are null, the user is absent for that day
      if (checkIn == null && checkOut == null) {
        continue; // Skip, will mark absent later
      }

      // Record the day of the check-in
      if (checkIn != null) {
        daysWithRecords.add(checkIn.day);
      }

      // Determine if the user was late
      if (checkIn != null && checkIn.isAfter(lateThreshold)) {
        counts['late'] = (counts['late'] ?? 0) + 1;
      } else if (checkIn != null) {
        counts['present'] = (counts['present'] ?? 0) + 1;
      }
    }

    // Calculate absences by checking which past and current days are missing records
    for (int day = 1; day <= currentDayOfMonth; day++) {
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

class Monthlyattendance extends StatelessWidget {
  final int presentCount;
  final int lateCount;
  final int absentCount;

  const Monthlyattendance({
    Key? key,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    double baseFontSize = 20;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    double baseFontSize1 = 14;
    double responsiveFontSize1 = baseFontSize1 * (screenWidth / 375);

    return Row(
      children: [
        // ignore: sized_box_for_whitespace
        Container(
          height: 90,
          width: 90,
          child: PieChart(
            PieChartData(sections: [
              PieChartSectionData(
                color: Colors.purple,
                value: presentCount.toDouble(),
                title: '',
                radius: 12,
              ),
              PieChartSectionData(
                color: Colors.orange,
                value: lateCount.toDouble(),
                title: '',
                radius: 12,
              ),
              PieChartSectionData(
                color: Colors.red,
                value: absentCount.toDouble(),
                title: '',
                radius: 12,
              ),
            ], sectionsSpace: 0, centerSpaceRadius: 26),
          ),
        ),
        SizedBox(width: screenWidth * 0.05),
        SizedBox(
          width: screenWidth * 0.57,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      presentCount.toString(),
                      style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff8E71DF)),
                    ),
                    Text(
                      'Present',
                      style: TextStyle(
                          fontSize: responsiveFontSize1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff9E9E9E)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.06),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lateCount.toString(),
                      style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffF6C15B)),
                    ),
                    Text(
                      'Late',
                      style: TextStyle(
                          fontSize: responsiveFontSize1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff9E9E9E)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: screenWidth * 0.06,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      absentCount.toString(),
                      style: TextStyle(
                          fontSize: responsiveFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffEC5851)),
                    ),
                    Text(
                      'Absent',
                      style: TextStyle(
                          fontSize: responsiveFontSize1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff9E9E9E)),
                    ),
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
