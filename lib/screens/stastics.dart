import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quaidtech/components/PreviousMonthStatusBuilder.dart';
import 'package:quaidtech/components/graphicalbuildermonthly.dart';
import 'package:quaidtech/components/graphicalweekly.dart';
import 'package:quaidtech/components/monthattendancce.dart';
import 'package:quaidtech/components/statusbuilderweekly.dart';
import 'package:quaidtech/components/weeklyattenance.dart';
import 'package:quaidtech/main.dart';
import 'package:quaidtech/screens/notification.dart';

class StatsticsScreen extends StatefulWidget {
  const StatsticsScreen({super.key});

  @override
  State<StatsticsScreen> createState() => _StatsticsScreenState();
}

class _StatsticsScreenState extends State<StatsticsScreen> {
  String dropdownValue1 = 'Weekly';
  String dropdownValue2 = 'Select';
  String? selectedMonth;
  String? selectedYear;

  final List<String> months =
      List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> years =
      List.generate(12, (index) => (DateTime.now().year - index).toString());
  int _selectedIndex = 0;
  List<Map<String, dynamic>> attendanceDetails = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Widget _buildWeeklyAttendance(
    String text,
    Color color,
    String dropdownValue2,
  ) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    double baseFontSize6 = 18;
    double responsiveFontSize18 = baseFontSize6 * (screenWidth / 375);
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.tertiary,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: responsiveFontSize18,
                height: 0,
              ),
            ),
            const SizedBox(height: 20),
            WeeklyAttendance(
              color: color,
              dropdownValue2: dropdownValue2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyAttendance(
      String text, Color color, String dropdownValue2) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.tertiary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 0,
            ),
          ),
          const SizedBox(height: 10),
          MonthlyAttendance(
            color: color,
            dropdownValue2: dropdownValue2,
            uid: uid,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String text, int index) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    double baseFontSize = 16;
    double responsiveFontSize = baseFontSize * (screenWidth / 375);
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(48.0),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: responsiveFontSize,
                height: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceBasedOnSelection(String dropdownValue2,
      {required bool isWeekly}) {
    String detailsType;
    Color detailsColor;

    switch (dropdownValue2) {
      case 'Late Arrival':
        detailsType = 'Late Arrival Details';
        detailsColor = StatusTheme.theme.colorScheme.primary;
        break;
      case 'Absent':
        detailsType = 'Absent Details';
        detailsColor = StatusTheme.theme.colorScheme.secondary;
        break;
      case 'On Time':
        detailsType = 'On Time Details';
        detailsColor = StatusTheme.theme.colorScheme.inversePrimary;
        break;
      case 'Early Out':
        detailsType = 'Early Out Details';
        detailsColor = StatusTheme.theme.colorScheme.tertiary;
        break;
      case 'Present':
        detailsType = 'Present Details';
        detailsColor = StatusTheme.theme.colorScheme.surface;
        break;
      default:
        return const SizedBox.shrink();
    }

    return isWeekly
        ? _buildWeeklyAttendance(detailsType, detailsColor, dropdownValue2)
        : _buildMonthlyAttendance(detailsType, detailsColor, dropdownValue2);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    double baseFontSize20 = 20;
    double responsiveFontSize20 = baseFontSize20 * (screenWidth / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0.sp, vertical: 15.0.sp),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50.sp,
                  ),
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      height: 0,
                    ),
                  ),
                  SizedBox(
                    width: 50.sp,
                    height: 50.sp,
                    child: Material(
                      elevation: 10,
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          elevation: 5,
                          color: Theme.of(context).colorScheme.tertiary,
                          child: SizedBox(
                            width: 50.sp,
                            height: 50.sp,
                            child: Center(
                              child: Image.asset(
                                'assets/notification_icon.png',
                                width: 30.sp,
                                height: 30.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 15.sp,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20.sp),
                      if (dropdownValue1 == 'Weekly' && _selectedIndex == 0 ||
                          dropdownValue1 == 'Monthly' && _selectedIndex == 0)
                        Column(
                          children: [
                            Material(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).colorScheme.tertiary,
                              elevation: 5,
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.0.sp,
                                    vertical: 20.sp,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Filter',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          height: 0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6.sp),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10.sp),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: DropdownButton<String>(
                                                value: dropdownValue1,
                                                // ignore: prefer_const_constructors
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                iconSize: responsiveFontSize20,
                                                elevation: 16,
                                                isExpanded: true,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16.sp,
                                                  height: 0,
                                                ),
                                                underline: const SizedBox(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    dropdownValue1 = newValue!;
                                                  });
                                                },
                                                items: <String>[
                                                  'Weekly',
                                                  'Monthly',
                                                ].map<DropdownMenuItem<String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 20.sp),
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: DropdownButton<String>(
                                                value: dropdownValue2,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                iconSize: responsiveFontSize20,
                                                elevation: 16,
                                                isExpanded: true,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16.sp,
                                                  height: 0,
                                                ),
                                                underline: const SizedBox(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    dropdownValue2 = newValue!;
                                                  });
                                                },
                                                items: <String>[
                                                  'Select',
                                                  'Late Arrival',
                                                  'Absent',
                                                  'On Time',
                                                  'Early Out',
                                                  'Present'
                                                ].map<DropdownMenuItem<String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      if (dropdownValue1 == 'Weekly')
                        if (dropdownValue2 != 'Present' &&
                            dropdownValue2 != 'On Time' &&
                            dropdownValue2 != 'Absent' &&
                            dropdownValue2 != 'Early Out' &&
                            dropdownValue2 != 'Late Arrival')
                          Column(
                            children: [
                              Container(
                                height: 65,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(60),
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                                child: Row(
                                  children: [
                                    _buildSegment('Details Stats', 0),
                                    _buildSegment('Graphical View', 1),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      Column(
                        children: [
                          if (_selectedIndex != 1)
                            if (dropdownValue1 == 'Weekly') ...[
                              _buildAttendanceBasedOnSelection(dropdownValue2,
                                  isWeekly: true),
                            ] else if (dropdownValue1 == 'Monthly') ...[
                              _buildAttendanceBasedOnSelection(dropdownValue2,
                                  isWeekly: false),
                            ],
                        ],
                      ),
                      if (dropdownValue2 != 'Present' &&
                          dropdownValue2 != 'On Time' &&
                          dropdownValue2 != 'Absent' &&
                          dropdownValue2 != 'Early Out' &&
                          dropdownValue2 != 'Late Arrival')
                        if (dropdownValue1 == 'Weekly' && _selectedIndex == 0)
                          const StatusBuilderWeekly(),
                      if (dropdownValue2 != 'Present' &&
                          dropdownValue2 != 'On Time' &&
                          dropdownValue2 != 'Absent' &&
                          dropdownValue2 != 'Early Out' &&
                          dropdownValue2 != 'Late Arrival')
                        if (dropdownValue1 == 'Monthly' && _selectedIndex == 0)
                          Builder(builder: (context) {
                            selectedMonth = null;
                            selectedYear = null;
                            return Column(children: [
                              PreviousMonthlyAttendance(
                                uid: uid,
                                callbackYear: (p0) {
                                  selectedYear = p0;
                                  log(selectedYear!);
                                },
                                callbackMonth: (p0) {
                                  selectedMonth = p0;
                                  log(selectedMonth!);
                                },
                              ),
                            ]);
                          }),
                      if (dropdownValue1 == 'Weekly' && _selectedIndex == 1)
                        const GraphicalbuilderWeekly(),
                      if (dropdownValue1 == 'Monthly' && _selectedIndex == 1)
                        selectedMonth == null && selectedYear == null
                            ? GraphicalbuilderMonthly(
                                year: DateTime.now().year,
                                month: DateTime.now().month,
                              )
                            : GraphicalbuilderMonthly(
                                year: int.parse(selectedYear!),
                                month: int.parse(selectedMonth!),
                              ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
