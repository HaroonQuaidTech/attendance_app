import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;
import 'package:quaidtech/main.dart';

class GraphicalbuilderWeekly extends StatefulWidget {
  const GraphicalbuilderWeekly({super.key});

  @override
  State<GraphicalbuilderWeekly> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<GraphicalbuilderWeekly> {
  DateTime selectedDay = DateTime.now();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>?> fetchWeeklyAttendance(
      String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));

      List<DateTime> validDates = List.generate(5, (index) {
        DateTime date = monday.add(Duration(days: index));
        return date.isAfter(now) || date.weekday >= DateTime.saturday
            ? null
            : date;
      }).whereType<DateTime>().toList();

      List<String> formattedDates = validDates.map((date) {
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

      List<Map<String, dynamic>> weeklyData = snapshots.map((doc) {
        if (doc.exists && doc.data() != null) {
          return Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>);
        } else {
          return <String, dynamic>{};
        }
      }).toList();

      return weeklyData;
    } catch (e) {
      return null;
    }
  }

  Map<int, double> calculateWeeklyHourss(List<Map<String, dynamic>> data) {
    Map<int, double> weeklyHours = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    DateTime currentDate = DateTime.now();

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();

      if (checkIn != null &&
          checkOut != null &&
          checkIn.isBefore(currentDate)) {
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
      "On Time": 0,
      "Early Out": 0,
      "Late Arrival": 0,
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
            weeklyHoursss["On Time"] =
                (weeklyHoursss["On Time"] ?? 0) + duration.inHours.toDouble();
            break;
          case 4:
            weeklyHoursss["Early Out"] =
                (weeklyHoursss["Early Out"] ?? 0) + duration.inHours.toDouble();
            break;
          case 5:
            weeklyHoursss["Late Arrival"] =
                (weeklyHoursss["Late Arrival"] ?? 0) +
                    duration.inHours.toDouble();
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
        if ((checkInTime.hour == 7 && checkInTime.minute >= 50) ||
            (checkInTime.hour == 8 && checkInTime.minute <= 15)) {
          attendanceStats["On Time"] = (attendanceStats["On Time"] ?? 0) + 1;
        }

        if (checkInTime.hour == 8 && checkInTime.minute > 15) {
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
            checkInTime.year, checkInTime.month, checkInTime.day, 8, 16))) {
          lateCount++;
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

  int getOnTimeCount(List<Map<String, dynamic>> data) {
    int onTimeCount = 0;

    for (var entry in data) {
      final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();

      if (checkIn != null) {
        final checkInTime = TimeOfDay.fromDateTime(checkIn);

        // Check if the check-in is between 7:50 and 8:10 for "On Time"
        if ((checkInTime.hour == 7 && checkInTime.minute >= 50) ||
            (checkInTime.hour == 8 && checkInTime.minute <= 16)) {
          onTimeCount++;
        }
      }
    }
    return onTimeCount;
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

  Map<String, double> weeklyHoursss = {
    'Present': 0, // hours present
    'Absent': 0, // days absent
    'On Time': 0, // early on time
    'Early Out': 0, // early check-outs
    'Late Arrival': 0, // late days
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
          return const Padding(
            padding: EdgeInsets.only(top: 240.0),
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return const Text('Error loading data');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
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
          );
        }

        Map<int, double> weeklyHours = calculateWeeklyHourss(snapshot.data!);

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
                    const Text(
                      'Weekly',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 18,
                          width: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'TAT (Turn Around Time)',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 400,
                      child: BarChart(
                        BarChartData(
                          maxY: 9,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}H',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 0,
                                    ),
                                  );
                                },
                                reservedSize: 25,
                                interval: 1,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 30),
                                      Text(
                                        [
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thur',
                                          'Fri'
                                        ][value.toInt()],
                                        style: const TextStyle(
                                          fontSize: 14,
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
                            for (int day = 1; day <= 5; day++)
                              BarChartGroupData(
                                x: day - 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: weeklyHours[day] ?? 0,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 25,
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 9,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                    const Text(
                      'Weekly',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            legendOptions: const LegendOptions(
                              legendPosition: LegendPosition.top,
                              showLegendsInRow: true,
                              showLegends: true,
                              legendShape: BoxShape.circle,
                              legendTextStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                height: 0,
                              ),
                            ),
                            chartValuesOptions: const ChartValuesOptions(
                              showChartValues: false,
                            ),
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
