import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quaidtech/main.dart';

Future<Map<String, int>> fetchMonthlyAttendance(String userId) async {
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

    final currentDayOfMonth = now.day;

    if (querySnapshot.docs.isEmpty) {
      return {'present': 0, 'late': 0, 'absent': currentDayOfMonth};
    }

    final lateThreshold = DateTime(now.year, now.month, now.day, 8, 16);

    Map<String, int> counts = {
      'present': 0,
      'late': 0,
      'absent': 0,
    };

    Set<int> daysWithRecords = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();

      if (checkIn == null && checkOut == null) {
        continue;
      }

      if (checkIn != null) {
        daysWithRecords.add(checkIn.day);
      }

      if (checkIn != null && checkIn.isAfter(lateThreshold)) {
        counts['late'] = (counts['late'] ?? 0) + 1;
      } else if (checkIn != null) {
        counts['present'] = (counts['present'] ?? 0) + 1;
      }
    }

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
    super.key,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          height: 80.sp,
          width: 90.sp,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: StatusTheme.theme.colorScheme.surface,
                  value: presentCount.toDouble(),
                  title: '',
                  radius: 10.sp,
                ),
                PieChartSectionData(
                  color: StatusTheme.theme.colorScheme.primary,
                  value: lateCount.toDouble(),
                  title: '',
                  radius: 10.sp,
                ),
                PieChartSectionData(
                  color: StatusTheme.theme.colorScheme.secondary,
                  value: absentCount.toDouble(),
                  title: '',
                  radius: 10.sp,
                ),
              ],
              sectionsSpace: 0.sp,
              centerSpaceRadius: 22.sp,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              presentCount.toString(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: StatusTheme.theme.colorScheme.surface,
                height: 0,
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              'Present',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.secondary,
                height: 0,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              lateCount.toString(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: StatusTheme.theme.colorScheme.primary,
                height: 0,
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              'Late',
              style: TextStyle(
                      fontSize: 16.sp,
                color: Theme.of(context).colorScheme.secondary,
                height: 0,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              absentCount.toString(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: StatusTheme.theme.colorScheme.secondary,
                height: 0,
              ),
            ),
            SizedBox(height: 6.sp),
            Text(
              'Absent',
              style: TextStyle(
                  fontSize: 16.sp,
                color: Theme.of(context).colorScheme.secondary,
                height: 0,
              ),
            ),
          ],
        )
      ],
    );
  }
}
