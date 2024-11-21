import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PreviousMonthlyAttendance extends StatefulWidget {
  final String uid;

  const PreviousMonthlyAttendance({Key? key, required this.uid})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PreviousMonthlyAttendanceState createState() =>
      _PreviousMonthlyAttendanceState();
}

class _PreviousmonthstatusbuilderState
    extends State<Previousmonthstatusbuilder> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> attendanceDetails = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Future<void> fetchAttendance() async {
    final details =
        await _getMonthlyAttendanceDetails(uid, selectedYear, selectedMonth);
    setState(() {
      attendanceDetails = details;
    });
  }

  Future<List<Map<String, dynamic>>> _getMonthlyAttendanceDetails(
      String uid, int selectedYear, int selectedMonth) async {
    List<Map<String, dynamic>> monthlyAttendanceList = [];

    // Calculate the first and last day of the selected month
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    final lastDayOfMonth =
        DateTime(selectedYear, selectedMonth + 1, 0); // Last day of the month
    final totalDays = lastDayOfMonth.day;

    // Generate the list of document snapshot futures for the selected month
    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> snapshotFutures =
        List.generate(totalDays, (i) {
      final date = firstDayOfMonth.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date);
      return FirebaseFirestore.instance
          .collection('AttendanceDetails')
          .doc(uid)
          .collection('dailyattendance')
          .doc(formattedDate)
          .get();
    });

    // Await all snapshot fetches
    final snapshots = await Future.wait(snapshotFutures);

    // Process each day of the month
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

  Widget _buildWeekendContainer(int index) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 10),
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 55,
            decoration: BoxDecoration(
                color: Colors.blueGrey, borderRadius: BorderRadius.circular(6)),
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          const Padding(
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              'Weekend Days',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAttendance(
      {required Color color, required List<Map<String, dynamic>?> data}) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No attendance data found.',
          style: TextStyle(fontSize: 20),
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
        if (date.isAfter(now) || attendanceRecord == null) {
          return _buildHNullAttendanceContainer(index);
        }
        final checkIn = (attendanceRecord['checkIn'] as Timestamp?)?.toDate();
        final checkOut = (attendanceRecord['checkOut'] as Timestamp?)?.toDate();
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
    if (checkIn != null) {
      final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
      const TimeOfDay earlyOnTime = TimeOfDay(hour: 7, minute: 50);
      const TimeOfDay lateOnTime = TimeOfDay(hour: 8, minute: 10);
      const TimeOfDay exactCheckIn = TimeOfDay(hour: 8, minute: 0);
      const TimeOfDay lateArrival = TimeOfDay(hour: 8, minute: 10);
      if ((checkInTime.hour == earlyOnTime.hour &&
              checkInTime.minute >= earlyOnTime.minute) ||
          (checkInTime.hour == lateOnTime.hour &&
              checkInTime.minute <= lateOnTime.minute) ||
          (checkInTime.hour > earlyOnTime.hour &&
              checkInTime.hour < lateOnTime.hour)) {
        return const Color(0xff22AF41);
      } else if (checkInTime.hour > lateArrival.hour ||
          (checkInTime.hour == lateArrival.hour &&
              checkInTime.minute > lateArrival.minute)) {
        return const Color(0xffF6C15B);
      } else if (checkInTime.hour == exactCheckIn.hour &&
          checkInTime.minute == exactCheckIn.minute) {
        return const Color(0xff8E71DF);
      }
    }
    if (checkOut != null) {
      final TimeOfDay checkOutTime = TimeOfDay.fromDateTime(checkOut);
      const TimeOfDay earlyCheckout = TimeOfDay(hour: 17, minute: 0);
      if (checkOutTime.hour < earlyCheckout.hour ||
          (checkOutTime.hour == earlyCheckout.hour &&
              checkOutTime.minute < earlyCheckout.minute)) {
        return const Color.fromARGB(255, 223, 103, 11);
      }
    }
    return const Color(0xff8E71DF);
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

  Widget _buildEmptyAttendanceContainer(int index) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
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

  Widget _buildHNullAttendanceContainer(int index) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 10),
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          const Text(
            'Data Not Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 0,
            ),
          )
        ],
      ),
    );
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
      width: 53,
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
                fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            day,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not Available';
    final DateFormat formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
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
              fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
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

  @override
  Widget build(BuildContext context) {
    return  Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          width: 330,
          child: const Center(child: Text('previous month screen')),
        ),
      ],
    );
  }
}
