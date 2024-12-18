import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/main.dart';

class StatusBuilderWeekly extends StatefulWidget {
  const StatusBuilderWeekly({
    super.key,
  });
  @override
  State<StatusBuilderWeekly> createState() => _StatusBuilerState();
}

class _StatusBuilerState extends State<StatusBuilderWeekly> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Future<List<Map<String, dynamic>>> _getWeeklyAttendanceDetails(
      String uid) async {
    List<Map<String, dynamic>> weeklyAttendanceList = [];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final currentDayOfWeek = now.weekday - 1;

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> snapshotFutures =
        List.generate(currentDayOfWeek + 1, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date);
      return FirebaseFirestore.instance
          .collection('AttendanceDetails')
          .doc(uid)
          .collection('dailyattendance')
          .doc(formattedDate)
          .get();
    });

    final snapshots = await Future.wait(snapshotFutures);

    for (int i = 0; i <= currentDayOfWeek; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date);
      final snapshot = snapshots[i];
      final data = snapshot.data();
      final checkIn = (data?['checkIn'] as Timestamp?)?.toDate();

      if (snapshot.exists && checkIn != null) {
        weeklyAttendanceList.add(data!);
      } else {
        weeklyAttendanceList.add({
          'date': formattedDate,
          'status': 'Absent',
        });
      }
    }

    return weeklyAttendanceList;
  }

  Future<Map<String, dynamic>> _getWeeklyData(String userId) async {
    final attendanceData = await _getWeeklyAttendanceDetails(userId);
    final totalHoursData = _calculateWeeklyHours(attendanceData);
    return {
      'attendanceData': attendanceData,
      'totalHours': totalHoursData,
    };
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

  int _calculateWeeklyMins(List<Map<String, dynamic>?> weeklyData) {
    int totalMinutes = 0;
    for (var data in weeklyData) {
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

  double _calculateWeeklyHours(List<Map<String, dynamic>?> weeklyData) {
    int totalMinutes = 0;
    for (var data in weeklyData) {
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
    final date = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1 - index));
    final formattedDate = DateFormat('dd').format(date);
    final day = DateFormat('EE').format(date);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          height: 82.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60.sp,
                height: 58.sp,
                decoration: BoxDecoration(
                  color: StatusTheme.theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      day,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Leave/Day off',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  height: 0,
                ),
              ),
              SizedBox(width: 10.sp),
            ],
          ),
        ),
        SizedBox(height: 10.sp),
      ],
    );
  }

  Widget _buildAttendance({required List<Map<String, dynamic>?> data}) {
    return ListView.builder(
      itemCount: data.length,
      primary: false,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final attendanceRecord = data[index];
        final DateTime date = DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1 - index),
        );

        final String day = DateFormat('EE').format(date);
        final String formattedDate = DateFormat('dd').format(date);
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          return const SizedBox.shrink();
        }
        final checkIn = (attendanceRecord?['checkIn'] as Timestamp?)?.toDate();
        final checkOut =
            (attendanceRecord?['checkOut'] as Timestamp?)?.toDate();
        if (checkIn == null && checkOut == null) {
          return _buildEmptyAttendanceContainer(index);
        }
        final totalHours = _calculateTotalHours(checkIn, checkOut);
        Color containerColor = _determineContainerColor(checkIn, checkOut);
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              height: 82.sp,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDateColumn(formattedDate, day, containerColor),
                  _buildTimeColumn(checkIn, 'Check In'),
                  const VerticalDivider(color: Colors.black, width: 1),
                  _buildTimeColumn(checkOut, 'Check Out'),
                  const VerticalDivider(color: Colors.black, width: 1),
                  _buildHoursColumn(totalHours),
                ],
              ),
            ),
            SizedBox(height: 10.sp),
          ],
        );
      },
    );
  }

  Color _determineContainerColor(DateTime? checkIn, DateTime? checkOut) {
    const TimeOfDay onTime = TimeOfDay(hour: 8, minute: 15);
    const TimeOfDay lateArrival = TimeOfDay(hour: 8, minute: 16);
    const TimeOfDay earlyCheckout = TimeOfDay(hour: 17, minute: 0);
    Color containerColor = StatusTheme.theme.colorScheme.secondary;
    if (checkIn != null) {
      final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
      if (checkInTime.hour < onTime.hour ||
          (checkInTime.hour == onTime.hour &&
              checkInTime.minute <= onTime.minute)) {
        containerColor = StatusTheme.theme.colorScheme.inversePrimary;
      } else if (checkInTime.hour > lateArrival.hour ||
          (checkInTime.hour == lateArrival.hour &&
              checkInTime.minute >= lateArrival.minute)) {
        containerColor = StatusTheme.theme.colorScheme.primary;
      }
    }
    if (checkOut != null) {
      final TimeOfDay checkOutTime = TimeOfDay.fromDateTime(checkOut);
      if (checkOutTime.hour < earlyCheckout.hour ||
          (checkOutTime.hour == earlyCheckout.hour &&
              checkOutTime.minute < earlyCheckout.minute)) {
        containerColor = StatusTheme.theme.colorScheme.tertiary;
      }
    }
    return containerColor;
  }

  Widget _buildDateColumn(
      String formattedDate, String day, Color containerColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60.sp,
          height: 58.sp,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 0,
                ),
              ),
              SizedBox(height: 5.sp),
              Text(
                day,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeColumn(DateTime? time, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          time != null ? _formatTime(time) : '--:--',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildHoursColumn(String totalHours) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          totalHours,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            height: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Total Hrs',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            height: 0,
          ),
        ),
      ],
    );
  }

  String _convertMinutesToTimeFormat(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}.${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 4));
    final dateRange =
        '${DateFormat('dd MMM').format(startOfWeek)} - ${DateFormat('dd MMM').format(endOfWeek)}';

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getWeeklyData(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 150.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error: Something went wrong. Check Your Internet Connection.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Text(
                    'No Data Available',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final attendanceData = snapshot.data!['attendanceData']
                      as List<Map<String, dynamic>?>? ??
                  [];
              final totalMinutes = _calculateWeeklyMins(attendanceData);
              final totalHoursFormatted =
                  _convertMinutesToTimeFormat(totalMinutes);

              const double maxHours = 45;
              final double progress = totalMinutes / 60 / maxHours;

              return Column(
                children: [
                  Material(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.tertiary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Times Log',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                            ),
                          ),
                          SizedBox(height: 20.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeCard(
                                screenHeight: screenHeight,
                                screenWidth: screenWidth,
                                title: 'Time in Minutes',
                                value: '$totalMinutes Mins',
                                progress: progress,
                                dateRange: dateRange,
                              ),
                              const SizedBox(height: 20),
                              _buildTimeCard(
                                screenHeight: screenHeight,
                                screenWidth: screenWidth,
                                title: 'Time in Hours',
                                value: '$totalHoursFormatted Hours',
                                progress: progress,
                                dateRange: dateRange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Attendance: $dateRange',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              height: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildAttendance(data: attendanceData),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

// Reusable widget for time display cards
  Widget _buildTimeCard({
    required double screenHeight,
    required double screenWidth,
    required String title,
    required String value,
    required double progress,
    required String dateRange,
  }) {
    return Container(
      height: screenHeight * 0.15,
      width: screenWidth * 0.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22.sp,
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              dateRange,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
