import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/main.dart';

class DailyEmptyAttendance extends StatefulWidget {
  final DateTime? selectedDay;
  final String? checkInTime;

  const DailyEmptyAttendance({
    super.key,
    required this.selectedDay,
    this.checkInTime,
  });

  @override
  State<DailyEmptyAttendance> createState() => _DailyAttendanceState();
}

class _DailyAttendanceState extends State<DailyEmptyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;

    String message;
    Color containerColor;

    final DateTime currentDate = DateTime.now();

    if (widget.selectedDay != null &&
        (widget.selectedDay!.weekday == DateTime.saturday ||
            widget.selectedDay!.weekday == DateTime.sunday)) {
      message = 'Weekend Days';
      containerColor = CustomTheme.theme.colorScheme.secondaryFixed;
    } else {
      if (widget.selectedDay!.isAfter(currentDate)) {
        message = 'No Data Available';
        containerColor = CustomTheme.theme.colorScheme.secondary;
      } else if (widget.checkInTime == null || widget.checkInTime!.isEmpty) {
        message = 'Leave/Day off';
        containerColor = CustomTheme.theme.colorScheme.secondary;
      } else {
        message = 'Checked in at ${widget.checkInTime}';
        containerColor = CustomTheme.theme.colorScheme.secondary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: screenHeight * 0.1,
      width: screenWidth * 0.85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.selectedDay != null
                          ? DateFormat('dd').format(widget.selectedDay!)
                          : '--',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.selectedDay != null
                          ? DateFormat('EE').format(widget.selectedDay!)
                          : '--',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 50),
          Center(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
