import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatusBuilderWeekly extends StatefulWidget {
  const StatusBuilderWeekly({
    super.key,
  });

  @override
  State<StatusBuilderWeekly> createState() => _StatusBuilerState();
}

class _StatusBuilerState extends State<StatusBuilderWeekly> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  Future<List<Map<String, dynamic>?>> _getAttendanceDetails(String uid) async {
    List<Map<String, dynamic>?> attendanceList = [];
    final now = DateTime.now();
    DateFormat('yMMMd').format(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    weekStart.add(const Duration(days: 6));

    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 5; i++) {
      final date = weekStart.add(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      DateTime currentDay = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat('yMMMd').format(currentDay);
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('AttendanceDetails')
              .doc(userId)
              .collection('dailyattendance')
              .doc(formattedDate)
              .get();

      if (snapshot.exists) {
        attendanceList.add(snapshot.data());
      } else {
        attendanceList.add(null);
      }
    }
    DateFormat('yMMMd').format(now);

    return attendanceList;
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

  Widget _buildEmptyAttendanceContainer(
    int index,
  ) {
    final DateTime date = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1 - index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 53,
                height: 55,
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 50.0),
            child: Text(
              'Leave/Day off',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNullAttendanceContainer(
    int index,
  ) {
    final DateTime date = DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1 - index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
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
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 53,
                height: 55,
                decoration: BoxDecoration(
                    color: const Color(0xff8E71DF),
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
                          color: Colors.white),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'Data not Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 0,
            ),
          ),
          const SizedBox(width: 0),
        ],
      ),
    );
  }

  Widget _buildAttendance({
    required Color color,
    required List<Map<String, dynamic>?> data,
  }) {
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: _getAttendanceDetails(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 200.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text(
            'Error Something went wrong Check Your Internet Connection',
            style: TextStyle(color: Colors.red),
          ));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 100.0),
            child: Center(
                child: Text('No attendance data found.',
                    style: TextStyle(fontSize: 20))),
          );
        }

        final weeklyData = snapshot.data!;

        return Expanded(
          child: ListView.builder(
            itemCount: weeklyData.length,
            itemBuilder: (context, index) {
              final data = weeklyData[index];
              final DateTime date = DateTime.now()
                  .subtract(Duration(days: DateTime.now().weekday - 1 - index));

              if (date.isAfter(DateTime.now())) {
                // If the date is in the future, return the null attendance container
                return _buildNullAttendanceContainer(index);
              }

              final String day = DateFormat('EE').format(date);
              final String formattedDate = DateFormat('dd').format(date);
              if (date.weekday == DateTime.saturday ||
                  date.weekday == DateTime.sunday) {
                return const SizedBox.shrink();
              }

              // Check if date is in the future
              final checkIn = (data?['checkIn'] as Timestamp?)?.toDate();
              final checkOut = (data?['checkOut'] as Timestamp?)?.toDate();

              if (checkIn == null && checkOut == null) {
                return _buildEmptyAttendanceContainer(index);
              }

              final totalHours = _calculateTotalHours(checkIn, checkOut);
              Color containerColor;

              if (checkIn != null) {
                final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
                const TimeOfDay onTime = TimeOfDay(hour: 8, minute: 14);
                const TimeOfDay lateArrival = TimeOfDay(hour: 8, minute: 15);

                final DateTime today = DateTime.now();
                final DateTime checkInDateTime = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  checkInTime.hour,
                  checkInTime.minute,
                );
                final DateTime onTimeDateTime = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  onTime.hour,
                  onTime.minute,
                );
                final DateTime lateArrivalDateTime = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  lateArrival.hour,
                  lateArrival.minute,
                );

                if (checkInDateTime.isBefore(onTimeDateTime)) {
                  containerColor = const Color(0xff22Af41); // On time
                } else if (checkInDateTime.isAfter(lateArrivalDateTime)) {
                  containerColor = const Color(0xffF6C15B); // Late arrival
                } else {
                  containerColor = const Color(0xff8E71DF); // Default color
                }
              } else {
                containerColor = const Color(0xffEC5851); // No check-in
              }

              if (checkOut != null) {
                final TimeOfDay checkOutTime = TimeOfDay.fromDateTime(checkOut);
                const TimeOfDay earlyCheckout = TimeOfDay(hour: 17, minute: 0);

                final DateTime today = DateTime.now();
                final DateTime checkOutDateTime = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  checkOutTime.hour,
                  checkOutTime.minute,
                );
                final DateTime earlyCheckoutDateTime = DateTime(
                  today.year,
                  today.month,
                  today.day,
                  earlyCheckout.hour,
                  earlyCheckout.minute,
                );

                if (checkOutDateTime.isBefore(earlyCheckoutDateTime)) {
                  containerColor = const Color(0xffF07E25); // Early check-out
                }
              }

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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 53,
                          height: 55,
                          decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(6)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              Text(
                                day,
                                style: const TextStyle(
                                    fontSize: 12,
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
                          checkIn != null ? _formatTime(checkIn) : '--:--',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const Text(
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
                      color: Colors.black,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          checkOut != null ? _formatTime(checkOut) : '--:--',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const Text(
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
                      color: Colors.black,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totalHours,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const Text(
                          'Total Hrs',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 4));
    final String startFormatted = DateFormat('dd MMM').format(startOfWeek);
    final String endFormatted = DateFormat('dd MMM').format(endOfWeek);

    return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(children: [
          FutureBuilder(
              future: _getAttendanceDetails(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text(
                    'Error Something went wrong Check Your Internet Connection',
                    style: TextStyle(color: Colors.red),
                  ));
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('.'));
                }
                final weeklyData = snapshot.data!;
                final totalTime = _calculateWeeklyMins(weeklyData);
                final totalHours = (totalTime / 60).toStringAsFixed(2);
                final totalMinutes = _calculateWeeklyMins(weeklyData);
                final totalHourss = _calculateWeeklyHours(weeklyData);

                const int maxMinutes = 2700; //weekly minutes
                const double maxHours = 45; //weekly hours

                final double progress = totalHourss / maxHours;

                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                      height: 207,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xffEFF1FF),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Weekly Times Log',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                              'Time in Mints',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              '$totalTime Mints',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 20),
                                            ),
                                            LinearProgressIndicator(
                                              value: totalMinutes / maxMinutes,
                                              backgroundColor: Colors.grey[300],
                                              color: const Color(0xff9478F7),
                                            ),
                                            Text(
                                              '$startFormatted - $endFormatted',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15),
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
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              '$totalHours Hours',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 20),
                                            ),
                                            LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.grey[300],
                                              color: const Color(0xff9478F7),
                                            ),
                                            Text(
                                              '$startFormatted - $endFormatted',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                              ]))),
                );
              }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            height: MediaQuery.of(context).size.height * 0.68,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xffEFF1FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Attendance: ${'$startFormatted - $endFormatted'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(height: 10),
                _buildAttendance(color: const Color(0xff9478F7), data: []),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ]));
  }
}
