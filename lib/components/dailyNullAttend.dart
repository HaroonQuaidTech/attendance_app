import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    String message;
    Color containerColor;

    final DateTime currentDate = DateTime.now();

    if (widget.selectedDay != null &&
        (widget.selectedDay!.weekday == DateTime.saturday ||
            widget.selectedDay!.weekday == DateTime.sunday)) {
      message = 'Weekend Days';
      containerColor = StatusTheme.theme.colorScheme.secondaryFixed;
    } else {
      if (widget.selectedDay!.isAfter(currentDate)) {
        message = 'No Data Available';
        containerColor = StatusTheme.theme.colorScheme.secondary;
      } else if (widget.checkInTime == null || widget.checkInTime!.isEmpty) {
        message = 'Leave/Day off';
        containerColor = StatusTheme.theme.colorScheme.secondary;
      } else {
        message = 'Checked in at ${widget.checkInTime}';
        containerColor = StatusTheme.theme.colorScheme.secondary;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 8.sp),
      width: 370.sp,
      height: 80.sp,
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
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.selectedDay != null
                          ? DateFormat('dd').format(widget.selectedDay!)
                          : '--',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.selectedDay != null
                          ? DateFormat('EE').format(widget.selectedDay!)
                          : '--',
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
          ),
          SizedBox(width: 50.sp),
          Center(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 22.sp,
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
