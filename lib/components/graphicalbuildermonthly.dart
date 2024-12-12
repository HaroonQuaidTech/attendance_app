import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;
import 'package:quaidtech/main.dart';

class GraphicalbuilderMonthly extends StatefulWidget {
  final int year;
  final int month;
  const GraphicalbuilderMonthly(
      {super.key, required this.year, required this.month});

  @override
  State<GraphicalbuilderMonthly> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<GraphicalbuilderMonthly> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>?> fetchMonthlyAttendance(
      String userId) async {
    try {
      log(widget.year.toString());
      log(widget.month.toString());
      DateTime now = DateTime(widget.year, widget.month,
          widget.month == DateTime.now().month ? DateTime.now().day : 1);
      DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      log(lastDayOfMonth.day.toString());

      List<Future<DocumentSnapshot>> futures = [];

      for (int i = 1; i <= lastDayOfMonth.day; i++) {
        DateTime date = DateTime(now.year, now.month, i);

        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday ||
            (date.isAfter(now) && widget.month == DateTime.now().month)) {
          log('Continue');
          continue;
        }

        String formattedDate = DateFormat('yMMMd').format(date);
        futures.add(FirebaseFirestore.instance
            .collection('AttendanceDetails')
            .doc(userId)
            .collection('dailyattendance')
            .doc(formattedDate)
            .get());
      }

      List<DocumentSnapshot> snapshots = await Future.wait(futures);

      List<Map<String, dynamic>> monthlyData = snapshots.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data() as Map)
            : Map<String, dynamic>.from({});
      }).toList();

      return monthlyData;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Map<String, double> calculateMonthlyHours(List<Map<String, dynamic>> data) {
    Map<String, double> monthlyHours = {
      "Week 1": 0,
      "Week 2": 0,
      "Week 3": 0,
      "Week 4": 0,
      "Week 5": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        int weekNumber = ((checkIn.day - 1) / 7).floor() + 1;

        switch (weekNumber) {
          case 1:
            monthlyHours["Week 1"] =
                (monthlyHours["Week 1"] ?? 0) + duration.inHours.toDouble();
            break;
          case 2:
            monthlyHours["Week 2"] =
                (monthlyHours["Week 2"] ?? 0) + duration.inHours.toDouble();
            break;
          case 3:
            monthlyHours["Week 3"] =
                (monthlyHours["Week 3"] ?? 0) + duration.inHours.toDouble();
            break;
          case 4:
            monthlyHours["Week 4"] =
                (monthlyHours["Week 4"] ?? 0) + duration.inHours.toDouble();
            break;
          case 5:
            monthlyHours["Week 5"] =
                (monthlyHours["Week 5"] ?? 0) + duration.inHours.toDouble();
            break;
        }
      }
    }

    return monthlyHours;
  }

  Map<String, double> calculateAttendanceStats(
      List<Map<String, dynamic>> data) {
    Map<String, double> attendanceStats = {
      "Present": 0,
      "Absent": 0,
      "On Time": 0,
      "Early Out": 0,
      "Late Arrival": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final checkInTime = TimeOfDay.fromDateTime(checkIn);
        final checkOutTime = TimeOfDay.fromDateTime(checkOut);
        if ((checkInTime.hour == 8 && checkInTime.minute <= 15)) {
          attendanceStats["On Time"] = (attendanceStats["On Time"] ?? 0) + 1;
        }

        if (checkInTime.hour > 8 ||
            (checkInTime.hour == 8 && checkInTime.minute > 15)) {
          attendanceStats["Late Arrival"] =
              (attendanceStats["Late Arrival"] ?? 0) + 1;
        }

        if (checkOutTime.hour < 17) {
          attendanceStats["Early Out"] =
              (attendanceStats["Early Out"] ?? 0) + 1;
        }
      } else {
        attendanceStats["Absent"] = (attendanceStats["Absent"] ?? 0) + 1;
      }
    }

    return attendanceStats;
  }

  int getLateArrivalCount(List<Map<String, dynamic>> attendanceData) {
    int lateCount = 0;
    DateTime now = DateTime.now();

    for (var entry in attendanceData) {
      if (entry['checkIn'] != null) {
        DateTime checkInTime = (entry['checkIn'] as Timestamp).toDate();
        DateTime checkInDate =
            DateTime(checkInTime.year, checkInTime.month, checkInTime.day);

        if (checkInDate.isBefore(now) || checkInDate.isAtSameMomentAs(now)) {
          if (checkInTime.isAfter(DateTime(
              checkInTime.year, checkInTime.month, checkInTime.day, 8, 16))) {
            lateCount++;
          }
        }
      }
    }
    return lateCount;
  }

  int getEarlyOutCount(List<Map<String, dynamic>> attendanceData) {
    int earlyCount = 0;

    for (var entry in attendanceData) {
      if (entry['checkOut'] != null) {
        DateTime checkOutTime = (entry['checkOut'] as Timestamp).toDate();

        if (checkOutTime.isBefore(DateTime(
            checkOutTime.year, checkOutTime.month, checkOutTime.day, 17, 0))) {
          earlyCount++;
        }
      }
    }

    return earlyCount;
  }

  int getOnTimeCount(List<Map<String, dynamic>> data) {
    return data.where((entry) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      if (checkIn == null) return false;

      final hour = checkIn.hour;
      final minute = checkIn.minute;

      return (hour == 7 && minute >= 50) || (hour == 8 && minute <= 15);
    }).length;
  }

  int getAbsentCount(List<dynamic> attendanceData) {
    int absentCount = 0;

    for (var record in attendanceData) {
      if (record['checkIn'] == null ||
          (record['status'] != null &&
              record['status'].toString().toLowerCase() == 'absent')) {
        absentCount++;
      }
    }

    return absentCount;
  }

  int getPresentCount(List<dynamic> attendanceData) {
    int presentCount = 0;

    for (var record in attendanceData) {
      if (record['checkIn'] != null) {
        presentCount++;
      }
    }

    return presentCount;
  }

  Map<String, double> weeklyHours = {
    'Present': 0,
    'Absent': 0,
    'Late Arrival': 0,
    'Early Out': 0,
    'On Time': 0,
  };
  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Map<String, double> monthlyHours = {};
  Map<String, double> monthlyAttendanceStats = {};

  Future<void> _loadMonthlyData() async {
    List<Map<String, dynamic>>? data = await fetchMonthlyAttendance(userId);
    if (data != null) {
      setState(() {
        monthlyHours = calculateMonthlyHours(data);
        monthlyAttendanceStats = calculateAttendanceStats(data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 20;
    double responsiveFontSize20 = baseFontSize * (screenWidth / 375);
    double baseFontSize2 = 16;
    double responsiveFontSize16 = baseFontSize2 * (screenWidth / 375);
    double baseFontSize3 = 14;
    double responsiveFontSize14 = baseFontSize3 * (screenWidth / 375);
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: fetchMonthlyAttendance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 240.0),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return const Text('Error loading data');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 80.0),
            child: Text('No attendance data available'),
          );
        }

        Map<String, double> monthlyHours =
            calculateMonthlyHours(snapshot.data!);
        calculateAttendanceStats(snapshot.data!);

        Map<String, double> pieChartData = {
          'Present': getPresentCount(snapshot.data!).toDouble(),
          'Absent': getAbsentCount(snapshot.data!).toDouble(),
          'On Time': getOnTimeCount(snapshot.data!).toDouble(),
          'Early Out': getEarlyOutCount(snapshot.data!).toDouble(),
          'Late Arrival': getLateArrivalCount(snapshot.data!).toDouble(),
        };

        return Column(
          children: [
            const SizedBox(height: 20),
            Material(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.tertiary,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: responsiveFontSize20,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: screenSize.height * 0.02,
                          width: screenSize.height * 0.02,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TAT (Turn Around Time)',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: responsiveFontSize16,
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                    SizedBox(
                      height: screenSize.height * 0.45,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 45,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}H',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: responsiveFontSize14,
                                      fontWeight: FontWeight.w600,
                                      height: 0,
                                    ),
                                  );
                                },
                                reservedSize: 40,
                                interval: 5,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  SizedBox(height: screenSize.height * 0.02);
                                  List<String> weekLabels = [
                                    'Week 1',
                                    'Week 2',
                                    'Week 3',
                                    'Week 4',
                                    'Week 5'
                                  ];
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 30),
                                      Text(
                                        weekLabels[value.toInt()],
                                        style: TextStyle(
                                          fontSize: responsiveFontSize14,
                                          fontWeight: FontWeight.w600,
                                          height: 0,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: [
                            for (int week = 1; week <= 5; week++)
                              BarChartGroupData(
                                x: week - 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: (monthlyHours["Week $week"] ?? 0)
                                        .clamp(0, 45),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: screenWidth * 0.065,
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 45,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Material(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.tertiary,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontSize: responsiveFontSize20,
                        fontWeight: FontWeight.w600,
                        height: 0,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    pieChartData.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                const Icon(
                                  Icons.warning,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "No Data Available",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    height: 0,
                                    fontSize: 20,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          )
                        : PieChart(
                            dataMap: pieChartData,
                            colorList: [
                              StatusTheme.theme.colorScheme.surface,
                              StatusTheme.theme.colorScheme.secondary,
                              StatusTheme.theme.colorScheme.inversePrimary,
                              StatusTheme.theme.colorScheme.tertiary,
                              StatusTheme.theme.colorScheme.primary,
                            ],
                            chartRadius:
                                MediaQuery.of(context).size.width / 1.7,
                            legendOptions: LegendOptions(
                              legendPosition: LegendPosition.top,
                              showLegendsInRow: true,
                              showLegends: true,
                              legendShape: BoxShape.circle,
                              legendTextStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: responsiveFontSize14,
                                height: 0,
                              ),
                            ),
                            chartValuesOptions: const ChartValuesOptions(
                              showChartValues: false,
                            ),
                            totalValue: pieChartData.values.isNotEmpty
                                ? pieChartData.values.reduce((a, b) => a + b)
                                : 1,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
