import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyEmptyAttendance extends StatefulWidget {
  final DateTime? selectedDay;
  final String? checkInTime; // Add a parameter to pass the check-in time.

  const DailyEmptyAttendance({
    super.key,
    required this.selectedDay,
    this.checkInTime, // Nullable to allow empty or missing data.
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

    // Determine the message and color based on the selected day and check-in time.
    String message;
    Color containerColor;

    // Get the current date
    final DateTime currentDate = DateTime.now();

    // Check if the selected day is a weekend
    if (widget.selectedDay != null &&
        (widget.selectedDay!.weekday == DateTime.saturday ||
            widget.selectedDay!.weekday == DateTime.sunday)) {
      message = 'Weekend Days';
      containerColor = Colors.blueGrey; // Grey color for the container
    } else {
      // Handle weekdays
      if (widget.selectedDay!.isAfter(currentDate)) {
        // If the selected day is after the current day
        message = 'No Data Available';
        containerColor = const Color(0xffEC5851); // Set container color
      } else if (widget.checkInTime == null || widget.checkInTime!.isEmpty) {
        // If there is no check-in time
        message = 'Leave/Day off';
        containerColor = const Color(0xffEC5851); // Set container color
      } else {
        // If there is a check-in time
        message = 'Checked in at ${widget.checkInTime}';
        containerColor = const Color(0xffEC5851); // Set container color
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: screenHeight * 0.1,
      width: screenWidth * 0.90,
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
                  color: containerColor, // Dynamically set container color
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
              message, // Display the appropriate message.
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
