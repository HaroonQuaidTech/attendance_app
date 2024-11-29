import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
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

  Widget _buildAttendance({
    required Color color,
    required List<Map<String, dynamic>?> data,
  }) {
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
        final int month = int.parse(selectedMonth!);
        final int year = int.parse(selectedYear!);

        final DateTime firstDayOfMonth = DateTime(year, month, 1);
        final DateTime date = firstDayOfMonth.add(Duration(days: index));

        final String day =
            DateFormat('EE').format(date); // Day of the week (e.g., Mon, Tue)
        final String formattedDate = DateFormat('dd').format(date);

        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          return _buildWeekendContainer(index);
        }
        if (date.isAfter(DateTime.now()) || attendanceRecord == null) {
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
          _buildCheckTimeColumn(
              checkIn != null
                  ? DateFormat('hh:mm a')
                      .format(checkIn) // Format Check-In Time
                  : 'N/A',
              'Check In'),
          _buildDivider(),
          _buildCheckTimeColumn(
              checkOut != null
                  ? DateFormat('hh:mm a')
                      .format(checkOut) // Format Check-Out Time
                  : 'N/A',
              'Check Out'),
          _buildDivider(),
          _buildCheckTimeColumn(totalHours ?? 'N/A', 'Total Hrs'),
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

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);

    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));

    final String day =
        DateFormat('EE').format(date); // Day of the week (e.g., Mon, Tue)
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

  Widget _buildHNullAttendanceContainer(int index) {
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);

    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));

    final String day =
        DateFormat('EE').format(date); // Day of the week (e.g., Mon, Tue)
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
          _buildDateBox(formattedDate, day),
          const SizedBox(width: 30),
          const Text(
            'Data Not Available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String date, String day) {
    return Container(
      width: 53,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xff8E71DF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
    );
  }

  Widget _buildWeekendContainer(int index) {
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);

    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));

    final String day =
        DateFormat('EE').format(date); // Day of the week (e.g., Mon, Tue)
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

  Widget _buildSegment(String text, int index) {
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
                fontSize: 18,
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

    return _buildWeeklyAttendance(detailsType, detailsColor, dropdownValue2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 60),
            Text(
              'Statistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                  height: 50,
                  width: 50,
                  child: Center(
                    child: Image.asset(
                      'assets/notification_icon.png',
                      height: 30,
                      width: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      if (_selectedIndex != 1)
                        Material(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).colorScheme.tertiary,
                          elevation: 5,
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: DropdownButton<String>(
                                            value: dropdownValue1,
                                            icon: const Icon(
                                                Icons.arrow_drop_down),
                                            iconSize: 24,
                                            elevation: 16,
                                            isExpanded: true,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
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
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
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
                                            iconSize: 24,
                                            elevation: 16,
                                            isExpanded: true,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
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
                                              return DropdownMenuItem<String>(
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
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Column(
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
                      ),
                      if (dropdownValue2 != 'Present' &&
                          dropdownValue2 != 'On Time' &&
                          dropdownValue2 != 'Absent' &&
                          dropdownValue2 != 'Early Out' &&
                          dropdownValue2 != 'Late Arrival')
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
                          PreviousMonthlyAttendance(
                            uid: uid,
                          ),
                      if (dropdownValue1 == 'Weekly' && _selectedIndex == 1)
                        const GraphicalbuilderWeekly(),
                      if (dropdownValue1 == 'Monthly' && _selectedIndex == 1)
                        const GraphicalbuilderMonthly()
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
