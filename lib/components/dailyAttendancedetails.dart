import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/main.dart';

class DailyAttendance extends StatefulWidget {
  const DailyAttendance({
    super.key,
    required this.data,
    required this.selectedDay,
  });
  final Map<String, dynamic>? data;
  final DateTime? selectedDay;

  @override
  State<DailyAttendance> createState() => _DailyAttendanceState();
}

class _DailyAttendanceState extends State<DailyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

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

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize = 20;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    double baseFontSize1 = 14;
    double responsiveFontSize1 = baseFontSize1 * (screenWidth / 375);
    double baseFontSize2 = 12;
    double responsiveFontSize2 = baseFontSize2 * (screenWidth / 375);
    final data = widget.data;

    DateTime? checkInTime = (data?['checkIn'] != null)
        ? (data!['checkIn'] as Timestamp).toDate()
        : null;
    DateTime? checkOutTime = (data?['checkOut'] != null)
        ? (data!['checkOut'] as Timestamp).toDate()
        : null;

    String checkInTimeFormatted = checkInTime != null
        ? DateFormat('hh:mm a').format(checkInTime)
        : '--:--';
    String checkOutTimeFormatted = checkOutTime != null
        ? DateFormat('hh:mm a').format(checkOutTime)
        : "--:--";

    final totalHours = _calculateTotalHours(checkInTime, checkOutTime);

    Color? boxColor;
    if (checkInTime != null) {
      final eightAM = DateTime(
        checkInTime.year,
        checkInTime.month,
        checkInTime.day,
        8,
        16,
      );
      if (checkInTime.isBefore(eightAM) ||
          checkInTime.isAtSameMomentAs(eightAM)) {
        boxColor = StatusTheme.theme.colorScheme.inversePrimary;
      } else {
        boxColor = StatusTheme.theme.colorScheme.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: screenSize.height * 0.09,
      width: screenSize.height * 0.42,
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
                width: screenSize.height * 0.065,
                height: screenSize.height * 0.066,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(widget.selectedDay!),
                      style: TextStyle(
                        fontSize: responsiveFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('EEE').format(widget.selectedDay!),
                      style: TextStyle(
                        fontSize: responsiveFontSize2,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 0,
                      ),
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
                checkInTimeFormatted,
                style: TextStyle(
                  fontSize: responsiveFontSize1,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Check In',
                style: TextStyle(
                  fontSize: responsiveFontSize2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            decoration: const BoxDecoration(color: Colors.black),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                checkOutTimeFormatted,
                style: TextStyle(
                  fontSize: responsiveFontSize1,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Check Out',
                style: TextStyle(
                  fontSize: responsiveFontSize2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            decoration: const BoxDecoration(color: Colors.black),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                totalHours,
                style: TextStyle(
                  fontSize: responsiveFontSize1,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Total Hrs',
                style: TextStyle(
                  fontSize: responsiveFontSize2,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
