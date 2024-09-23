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

  final querySnapshot = await attendanceCollection
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
      .get();

  int presentCount = 0;
  int lateCount = 0;
  int absentCount = 0;

  for (final doc in querySnapshot.docs) {
    final data = doc.data();
    final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
    final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

       final lateThreshold = DateTime(now.year, now.month, now.day, 9, 0);

      if (checkIn != null) {
        if (checkOut != null) {
          if (checkIn.isAfter(lateThreshold)) {
            lateCount++;
          } else {
            presentCount++;
          }
        } else {
          // Handle cases where check-out is null (could be considered absent for simplicity)
          absentCount++;
        }
      } else {
        absentCount++;
      }
    }

  return {
    'present': presentCount,
    'late': lateCount,
    'absent': absentCount,
  };
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
      
          height: 88,
          width: 90,
          child: PieChart(
            PieChartData(sections: [
              PieChartSectionData(
                color: Colors.purple,
                value:  presentCount.toDouble(),
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
        SizedBox(width: 20,),
        
        
        
        SizedBox(
          width: screenWidth*0.57,
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
