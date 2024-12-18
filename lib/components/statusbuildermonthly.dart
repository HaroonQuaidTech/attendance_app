import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/main.dart';

class StatusBuilderMonthly extends StatefulWidget {
  const StatusBuilderMonthly({super.key});
  @override
  State<StatusBuilderMonthly> createState() => _StatusBuilerState();
}

class _StatusBuilerState extends State<StatusBuilderMonthly> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> _getMonthlyAttendanceDetails(
      String uid) async {
    List<Map<String, dynamic>> monthlyAttendanceList = [];
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final today = now.day;

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> snapshotFutures =
        List.generate(today, (i) {
      final date = firstDayOfMonth.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date);
      return FirebaseFirestore.instance
          .collection('AttendanceDetails')
          .doc(uid)
          .collection('dailyattendance')
          .doc(formattedDate)
          .get();
    });

    final snapshots = await Future.wait(snapshotFutures);

    for (int i = 0; i < snapshots.length; i++) {
      final date = firstDayOfMonth.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date);
      final snapshot = snapshots[i];
      final data = snapshot.data();
      final checkIn = (data?['checkIn'] as Timestamp?)?.toDate();

      if (snapshot.exists && checkIn != null) {
        monthlyAttendanceList.add(data!);
      } else {
        monthlyAttendanceList.add({
          'date': formattedDate,
          'status': 'Absent',
        });
      }
    }

    return monthlyAttendanceList;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not Available';
    final DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  String _calculateTotalHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null || checkOut == null) {
      return "00:00";
    }
    Duration duration = checkOut.difference(checkIn);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    final String formattedHours = hours.toString().padLeft(2, '0');
    final String formattedMinutes = minutes.toString().padLeft(2, '0');
    return '$formattedHours:$formattedMinutes';
  }

  int _calculateMonthlyTotal(List<Map<String, dynamic>?> monthlyData) {
    int totalMinutes = 0;
    for (var data in monthlyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        totalMinutes += duration.inMinutes;
      }
    }
    return totalMinutes;
  }

  double _calculateMonthlyHours(List<Map<String, dynamic>?> monthlyData) {
    int totalMinutes = 0;
    for (var data in monthlyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        totalMinutes += duration.inMinutes;
      }
    }
    final double totalHours = totalMinutes / 60;
    return totalHours;
  }

  Widget _buildEmptyAttendanceContainer(int index) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: StatusTheme.theme.colorScheme.secondary,
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
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Leave/Day off',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 0,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildWeekendContainer(int index) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                    color: StatusTheme.theme.colorScheme.secondaryFixed,
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Weekend Days',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 0,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String getCurrentMonthDateRange() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final formattedFirstDay = DateFormat('dd MMM').format(firstDayOfMonth);
    final formattedLastDay = DateFormat('dd MMM').format(lastDayOfMonth);
    return '$formattedFirstDay - $formattedLastDay';
  }

  Widget _buildAttendance(
      {required Color color, required List<Map<String, dynamic>?> data}) {
    if (data.isEmpty) {
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
    return ListView.builder(
      itemCount: data.length,
      primary: false,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final attendanceRecord = data[index];
        final DateTime now = DateTime.now();
        final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
        final DateTime date = firstDayOfMonth.add(Duration(days: index));
        final String day = DateFormat('EE').format(date);
        final String formattedDate = DateFormat('dd').format(date);
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          return _buildWeekendContainer(index);
        }

        final checkIn = (attendanceRecord?['checkIn'] as Timestamp?)?.toDate();
        final checkOut =
            (attendanceRecord?['checkOut'] as Timestamp?)?.toDate();
        if (checkIn == null && checkOut == null) {
          return _buildEmptyAttendanceContainer(index);
        }
        final totalHours = _calculateTotalHours(checkIn, checkOut);
        final Color containerColor =
            _determineContainerColor(checkIn, checkOut);
        return _buildAttendanceRow(
          formattedDate: formattedDate,
          day: day,
          checkIn: checkIn,
          checkOut: checkOut,
          totalHours: totalHours,
          containerColor: containerColor,
        );
      },
    );
  }

  Color _determineContainerColor(DateTime? checkIn, DateTime? checkOut) {
    int timeOfDayToMinutes(TimeOfDay time) {
      return time.hour * 60 + time.minute;
    }

    if (checkIn != null) {
      final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);

      const TimeOfDay ontime = TimeOfDay(hour: 8, minute: 15);
      const TimeOfDay lateArrival = TimeOfDay(hour: 8, minute: 16);

      final int checkInMinutes = timeOfDayToMinutes(checkInTime);
      final int ontimeMinutes = timeOfDayToMinutes(ontime);
      final int lateArrivalMinutes = timeOfDayToMinutes(lateArrival);

      if (checkInMinutes <= ontimeMinutes) {
        return StatusTheme.theme.colorScheme.inversePrimary;
      } else if (checkInMinutes >= lateArrivalMinutes) {
        return StatusTheme.theme.colorScheme.primary;
      }
    }

    if (checkOut != null) {
      final TimeOfDay checkOutTime = TimeOfDay.fromDateTime(checkOut);
      const TimeOfDay earlyCheckout = TimeOfDay(hour: 17, minute: 0);
      if (checkOutTime.hour < earlyCheckout.hour ||
          (checkOutTime.hour == earlyCheckout.hour &&
              checkOutTime.minute < earlyCheckout.minute)) {
        return StatusTheme.theme.colorScheme.tertiary;
      }
    }
    return StatusTheme.theme.colorScheme.secondary;
  }

  Widget _buildAttendanceRow({
    required String formattedDate,
    required String day,
    required DateTime? checkIn,
    required DateTime? checkOut,
    required String? totalHours,
    required Color containerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      height: 82,
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDateContainer(formattedDate, day, containerColor),
          _buildCheckTimeColumn(checkIn, 'Check In'),
          _buildDivider(),
          _buildCheckTimeColumn(checkOut, 'Check Out'),
          _buildDivider(),
          _buildCheckTimeColumn(totalHours ?? 'N/A', 'Total Hrs'),
        ],
      ),
    );
  }

  Widget _buildDateContainer(
      String formattedDate, String day, Color containerColor) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: containerColor,
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
              height: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTimeColumn(dynamic timeOrHours, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeOrHours is DateTime
              ? _formatTime(timeOrHours)
              : timeOrHours.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.black,
    );
  }

  String _convertMinutesToTimeFormat(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> _getMonthlyData(String userId) async {
    final attendanceData = await _getMonthlyAttendanceDetails(userId);
    final totalHoursData =
        attendanceData.isNotEmpty ? _calculateMonthlyTotal(attendanceData) : 0;
    return {
      'attendanceData': attendanceData,
      'totalHours': totalHoursData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    DateFormat('dd MMM').format(startOfWeek);
    DateFormat('dd MMM').format(endOfWeek);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getMonthlyData(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 150.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final attendanceData = snapshot.data!['attendanceData']
                  as List<Map<String, dynamic>?>;

              final monthlyData = snapshot.data!['attendanceData']
                      as List<Map<String, dynamic>?>? ??
                  [];

              final totalTime = _calculateMonthlyTotal(monthlyData);
              log('total time: $totalTime');
              final totalHoursFormatted =
                  _convertMinutesToTimeFormat(totalTime);
              (totalTime / 60).toStringAsFixed(2);

              const int maxMinutes = 10392;
              const double maxHours = 173.2;

              final totalMinutes = _calculateMonthlyTotal(monthlyData);
              final totalHourss = _calculateMonthlyHours(monthlyData);

              double progressValue =
                  maxHours != 0 ? totalHourss / maxHours : 0.0;
              return Column(
                children: [
                  Material(
                    borderRadius: BorderRadius.circular(20),
                    elevation: 5,
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Times Log',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 0,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: screenHeight * 0.15,
                                width: screenWidth * 0.43,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time in Minutes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 0,
                                        ),
                                      ),
                                      Text(
                                        '$totalTime Minutes',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          height: 0,
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: totalMinutes / maxMinutes,
                                        backgroundColor: Colors.grey[300],
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      Text(
                                        getCurrentMonthDateRange(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: screenHeight * 0.15,
                                width: screenWidth * 0.43,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Time in Hours',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 0,
                                        ),
                                      ),
                                      Text(
                                        '$totalHoursFormatted Hours',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          height: 0,
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: progressValue,
                                        backgroundColor: Colors.grey[300],
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      Text(
                                        getCurrentMonthDateRange(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Attendance: ${getCurrentMonthDateRange()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          _buildAttendance(
                              color: const Color(0xff9478F7),
                              data: attendanceData),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
