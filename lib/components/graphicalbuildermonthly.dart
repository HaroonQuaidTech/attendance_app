// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_string_interpolations, depend_on_referenced_packages, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;

class GraphicalbuilerMonthly extends StatefulWidget {
  const GraphicalbuilerMonthly({super.key});

  @override
  State<GraphicalbuilerMonthly> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<GraphicalbuilerMonthly> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>?> fetchMonthlyAttendance(
      String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
      DateTime lastDayOfMonth =
          DateTime(now.year, now.month + 1, 0); // Last day of the current month

      List<Future<DocumentSnapshot>> futures = [];

      for (int i = 1; i <= lastDayOfMonth.day; i++) {
        String formattedDate =
            DateFormat('yMMMd').format(DateTime(now.year, now.month, i));
        futures.add(FirebaseFirestore.instance
            .collection('AttendanceDetails')
            .doc(userId)
            .collection('dailyattendance')
            .doc(formattedDate)
            .get());
      }

      List<DocumentSnapshot> snapshots = await Future.wait(futures);

      // Parse the snapshots into a list of maps
      List<Map<String, dynamic>> monthlyData = snapshots.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data() as Map)
            : Map<String, dynamic>.from({});
      }).toList();

      return monthlyData;
    } catch (e) {
      return null; // Return null if an error occurs
    }
  }

  Map<String, double> calculateMonthlyHours(List<Map<String, dynamic>> data) {
    Map<String, double> monthlyHours = {
      "Week 1": 0,
      "Week 2": 0,
      "Week 3": 0,
      "Week 4": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        int weekNumber =
            ((checkIn.day - 1) / 7).floor() + 1; // Determine week number

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
      "Early Out": 0,
      "On Time": 0,
      "Late Arrival": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final checkInTime = TimeOfDay.fromDateTime(checkIn);
        final checkOutTime = TimeOfDay.fromDateTime(checkOut);
         if ((checkInTime.hour == 7 && checkInTime.minute >= 50) ||
            (checkInTime.hour == 8 && checkInTime.minute <= 10)) {
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

    for (var entry in attendanceData) {
      if (entry['checkIn'] != null) {
        DateTime checkInTime = (entry['checkIn'] as Timestamp).toDate();

        if (checkInTime.isAfter(DateTime(
            checkInTime.year, checkInTime.month, checkInTime.day, 8, 15))) {
          lateCount++;
        }
      }
    }
    return lateCount;
  }

  int getEarlyOutCount(List<Map<String, dynamic>> attendanceData) {
    int earlyCount = 0;

    for (var entry in attendanceData) {
      // Check if 'checkOut' is not null before processing
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
    int onTimeCount = 0;

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();

      if (checkIn != null) {
        final checkInTime = TimeOfDay.fromDateTime(checkIn);

        // Check if the check-in is between 7:50 and 8:10 for "On Time"
        if ((checkInTime.hour == 7 && checkInTime.minute >= 50) ||
            (checkInTime.hour == 8 && checkInTime.minute <= 10)) {
          onTimeCount++;
        }
      }
    }

    return onTimeCount;
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
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: fetchMonthlyAttendance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 240.0),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error loading data');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: Text('No attendance data available'),
          );
        }

        // Get the monthly hours and attendance stats
        Map<String, double> monthlyHours =
            calculateMonthlyHours(snapshot.data!);
        Map<String, double> monthlyAttendanceStats =
            calculateAttendanceStats(snapshot.data!);
     

        Map<String, double> pieChartData = {
          'Present': monthlyHours.values.reduce((a, b) => a + b).toDouble(),
          'Absent': getAbsentCount(snapshot.data!) * 9.0,
          'Late Arrival': getLateArrivalCount(snapshot.data!).toDouble(),
          'Early Out': getEarlyOutCount(snapshot.data!).toDouble(),
            'On Time': getOnTimeCount(snapshot.data!).toDouble(),
        };

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            SizedBox(height: 20),
            // Monthly Bar Chart
            Container(
              height: 430,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xffEFF1FF),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    Row(
                      children: [
                        Container(
                          height: 18,
                          width: 16,
                          decoration: BoxDecoration(color: Color(0xff9478F7)),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'TAT (Turn Around Time)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Expanded(
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
                                  return Text('${value.toInt()}H',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold));
                                },
                                reservedSize: 28,
                                interval: 5,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return Text('Week 1',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600));
                                    case 1:
                                      return Text('Week 2',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600));
                                    case 2:
                                      return Text('Week 3',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600));
                                    case 3:
                                      return Text('Week 4',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600));
                                    default:
                                      return Text('');
                                  }
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [
                              BarChartRodData(
                                toY: monthlyHours["Week 1"]!,
                                color: Color(0xff9478F7),
                                width: 22,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 45,
                                  color: Colors.white,
                                ),
                              ),
                            ]),
                            BarChartGroupData(x: 1, barRods: [
                              BarChartRodData(
                                toY: monthlyHours["Week 2"]!,
                                color: Color(0xff9478F7),
                                width: 22,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 45,
                                  color: Colors.white,
                                ),
                              ),
                            ]),
                            BarChartGroupData(x: 2, barRods: [
                              BarChartRodData(
                                toY: monthlyHours["Week 3"]!,
                                color: Color(0xff9478F7),
                                width: 22,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 45,
                                  color: Colors.white,
                                ),
                              ),
                            ]),
                            BarChartGroupData(x: 3, barRods: [
                              BarChartRodData(
                                toY: monthlyHours["Week 4"]!,
                                color: Color(0xff9478F7),
                                width: 22,
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 45,
                                  color: Colors.white,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Monthly Pie Chart
            Container(
              padding: EdgeInsets.all(12),
              height: 430,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xffEFF1FF),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20),
                  pieChartData.isEmpty
                      ? Center(child: Text('No data available'))
                      : PieChart(
                          dataMap: pieChartData,
                          colorList: [
                            Color(0xff9478F7), // Present
                            Color(0xffEC5851), // Absent
                            Color(0xffF6C15B), // Late Arrival
                            Color(0xffF07E25), // Early Out
                                Color(0xff22AF41),  //oN TIME
                          ],
                          chartRadius: MediaQuery.of(context).size.width / 1.7,
                          legendOptions: LegendOptions(
                            legendPosition: LegendPosition.top,
                            showLegendsInRow: true,
                            showLegends: true,
                            legendShape: BoxShape.circle,
                            legendTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValues: false,
                          ),
                          totalValue: pieChartData.values.isNotEmpty
                              ? pieChartData.values.reduce((a, b) => a + b)
                              : 1,
                        ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}
