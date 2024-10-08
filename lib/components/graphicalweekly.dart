// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_string_interpolations, depend_on_referenced_packages

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;

class GraphicalbuilerWeekly extends StatefulWidget {
  const GraphicalbuilerWeekly({super.key});

  @override
  State<GraphicalbuilerWeekly> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<GraphicalbuilerWeekly> {
  DateTime selectedDay = DateTime.now();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>?> fetchWeeklyAttendance(
      String userId) async {
    // Fetching weekly attendance data for the current week.
    try {
      DateTime now = DateTime.now();
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));

      List<DateTime> weekDates =
          List.generate(5, (index) => monday.add(Duration(days: index)));

      List<String> formattedDates = weekDates.map((date) {
        return DateFormat('yMMMd').format(date);
      }).toList();

      List<Future<DocumentSnapshot>> futures =
          formattedDates.map((formattedDate) {
        return FirebaseFirestore.instance
            .collection('AttendanceDetails')
            .doc(userId)
            .collection('dailyattendance')
            .doc(formattedDate)
            .get();
      }).toList();

      List<DocumentSnapshot> snapshots = await Future.wait(futures);

      // Parse the snapshots into a list of maps
      List<Map<String, dynamic>> weeklyData = snapshots.map((doc) {
        return doc.exists
            ? Map<String, dynamic>.from(doc.data() as Map)
            : Map<String, dynamic>.from({});
      }).toList();

      return weeklyData;
    } catch (e) {
      log('Error fetching weekly attendance: $e');
      return null; // Return null if an error occurs
    }
  }

  Map<int, double> calculateWeeklyHourss(List<Map<String, dynamic>> data) {
    Map<int, double> weeklyHours = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        final dayOfWeek = checkIn.weekday;
        weeklyHours[dayOfWeek] =
            (weeklyHours[dayOfWeek] ?? 0) + duration.inHours.toDouble();
      }
    }

    return weeklyHours;
  }

  Map<String, double> calculateWeeklyHours(List<Map<String, dynamic>> data) {
    Map<String, double> weeklyHoursss = {
      "Present": 0,
      "Absent": 0,
      "Late Arrival": 0,
      "Early Out": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        final dayOfWeek = checkIn.weekday;

        switch (dayOfWeek) {
          case 1:
            weeklyHoursss["Present"] =
                (weeklyHoursss["Present"] ?? 0) + duration.inHours.toDouble();
            break;
          case 2:
            weeklyHoursss["Absent"] =
                (weeklyHoursss["Abesnt"] ?? 0) + duration.inHours.toDouble();
            break;
          case 3:
            weeklyHoursss["Early Out"] =
                (weeklyHoursss["Early Out"] ?? 0) + duration.inHours.toDouble();
            break;
          case 4:
            weeklyHoursss["Late Arrival"] =
                (weeklyHoursss["Fri"] ?? 0) + duration.inHours.toDouble();
            break;
        }
      }
    }

    return weeklyHoursss;
  }

  Map<String, double> calculateAttendanceStats(
      List<Map<String, dynamic>> data) {
    Map<String, double> attendanceStats = {
      "Present": 0,
      "Absent": 0,
      "Early Out": 0,
      "Late Arrival": 0,
    };

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null && checkOut != null) {
        final checkInTime = TimeOfDay.fromDateTime(checkIn);
        final checkOutTime = TimeOfDay.fromDateTime(checkOut);

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

  Map<String, double> weeklyHoursss = {
    "Present": 0,
    "Absent": 0,
    "Early Out": 0,
    "Late Arrival": 0,
  };

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    List<Map<String, dynamic>>? data = await fetchWeeklyAttendance(userId);
    if (data != null) {
      setState(() {
        weeklyHoursss = calculateWeeklyHours(data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>?>(
        future: fetchWeeklyAttendance(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.only(top: 80.0),
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

          // Get the weekly hours
          Map<int, double> weeklyHours = calculateWeeklyHourss(snapshot.data!);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              SizedBox(
                height: 20,
              ),
              Container(
                height: 482,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xffEFF1FF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2), // changes position of shadow
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
                        'Weekly',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 18),
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
                            maxY: 8,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}H',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  },
                                  reservedSize: 28,
                                  interval: 1,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return Text('Mon',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600));
                                      case 1:
                                        return Text('Tue',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600));
                                      case 2:
                                        return Text('Wed',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600));
                                      case 3:
                                        return Text('Thur',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600));
                                      case 4:
                                        return Text('Fri',
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
                                    toY: weeklyHours[1] ?? 0,
                                    color: Color(0xff9478F7),
                                    width: 22,  backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 8,
                      color: Colors.white,
                    ),)
                              ]),
                              BarChartGroupData(x: 1, barRods: [
                                BarChartRodData(
                                    toY: weeklyHours[2] ?? 0,
                                    color: Color(0xff9478F7),
                                    width: 22,  backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 8,
                      color: Colors.white,
                    ),)
                              ]),
                              BarChartGroupData(x: 2, barRods: [
                                BarChartRodData(
                                    toY: weeklyHours[3] ?? 0,
                                    color: Color(0xff9478F7),
                                    width: 22,  backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 8,
                      color: Colors.white,
                    ),)
                              ]),
                              BarChartGroupData(x: 3, barRods: [
                                BarChartRodData(
                                    toY: weeklyHours[4] ?? 0,
                                    color: Color(0xff9478F7),
                                    width: 22,  backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 8,
                      color: Colors.white,
                    ),)
                              ]),
                              BarChartGroupData(x: 4, barRods: [
                                BarChartRodData(
                                    toY: weeklyHours[5] ?? 0,
                                    color: Color(0xff9478F7),
                                    width: 22,
                                    
                             backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 8,
                      color: Colors.white,
                    ),)
                              ]),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 14),

                      //----------------------dot indicators--------------------------------
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24,
              ),
              Container(
                padding: EdgeInsets.all(12),
                height: 430,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xffEFF1FF),
                  // color: Colors.amber,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
                    PieChart(
                      dataMap: weeklyHoursss,
                      colorList: [
                        
                        
                        Color(0xff9478F7),// Present
                        Color(0xffEC5851),// Absent
                        Color(0xffF6C15B), // late arrival
                        Color(0xffF07E25),// early Out
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
                      totalValue: weeklyHoursss.values.reduce((a, b) => a + b),
                    ),
                  ],
                ),
              ),
            ]),
          );
        });
  }
}
