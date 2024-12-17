import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/components/graphicalbuildermonthly.dart';
import 'package:quaidtech/main.dart';

typedef DropdownCallbackYear = Function(String);
typedef DropdownCallbackMonth = Function(String);

class PreviousMonthlyAttendance extends StatefulWidget {
  final String uid;
  final DropdownCallbackYear callbackYear;
  final DropdownCallbackMonth callbackMonth;

  const PreviousMonthlyAttendance({
    super.key,
    required this.uid,
    required this.callbackYear,
    required this.callbackMonth,
  });

  @override
  State<PreviousMonthlyAttendance> createState() =>
      _PreviousMonthlyAttendanceState();
}

class _PreviousMonthlyAttendanceState extends State<PreviousMonthlyAttendance> {
  List<Map<String, dynamic>> monthlyAttendanceList = [];
  String? selectedMonth;
  int _selectedIndex = 0;
  int selectedIndex = 0;
  String? selectedYear;
  final List<String> months =
      List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> years =
      List.generate(10, (index) => (DateTime.now().year - index).toString());

  Future<List<Map<String, dynamic>>> _getMonthlyAttendanceDetails(
      String uid, int month, int year) async {
    monthlyAttendanceList.clear();
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final currentDate = DateTime.now();

    final daysInMonth = currentDate.month == month && currentDate.year == year
        ? currentDate.day
        : lastDayOfMonth.day;

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> snapshotFutures =
        List.generate(daysInMonth, (i) {
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
      final formattedDate = DateFormat('MMM d, yyyy').format(date);
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
   @override
     void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month.toString().padLeft(2, '0'); 
    selectedYear = now.year.toString();
  }

  String _getMonthDateRange() {
    if (selectedMonth == null || selectedYear == null) {
      return "Select a month and year";
    }
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);
    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    final DateFormat formatter = DateFormat('MMM d');
    return "${formatter.format(firstDayOfMonth)} - ${formatter.format(lastDayOfMonth)}";
  }

  Widget _buildAttendance({
    required Color color,
    required List<Map<String, dynamic>?> data,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No attendance data found.',
          style: TextStyle(fontSize: 20.sp),
        ),
      );
    }
    return Column(
      children: [
        ListView.builder(
          itemCount: data.length,
          primary: false,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final attendanceRecord = data[index];
            final int month = int.parse(selectedMonth!);
            final int year = int.parse(selectedYear!);
            final DateTime firstDayOfMonth = DateTime(year, month, 1);
            final DateTime date = firstDayOfMonth.add(Duration(days: index));
            final String day = DateFormat('EE').format(date);
            final String formattedDate = DateFormat('dd').format(date);

            if (date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday) {
              return _buildWeekendContainer(index);
            }

            final checkIn =
                (attendanceRecord!['checkIn'] as Timestamp?)?.toDate();
            final checkOut =
                (attendanceRecord['checkOut'] as Timestamp?)?.toDate();
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
        ),
      ],
    );
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
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Column(
      children: [
        Container(
          height: 80.sp,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    width: 60.sp,
                    height: 60.sp,
                    decoration: BoxDecoration(
                        color: StatusTheme.theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 0.sp,
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
              ),
              Text(
                'Leave/Day off',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  height: 0,
                ),
              ),
              SizedBox(height: 50.sp),
            ],
          ),
        ),
        SizedBox(height: 10.sp),
      ],
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

  Widget _buildWeekendContainer(int index) {
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);
    final DateTime firstDayOfMonth = DateTime(year, month, 1);
    final DateTime date = firstDayOfMonth.add(Duration(days: index));
    final String day = DateFormat('EE').format(date);
    final String formattedDate = DateFormat('dd').format(date);
    return Column(
      children: [
        Container(
          height: 80.sp,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                    color: StatusTheme.theme.colorScheme.secondaryFixed,
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              Text(
                'Weekend',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  height: 0,
                ),
              ),
              SizedBox(height: 50.sp),
            ],
          ),
        ),
        SizedBox(height: 10.sp),
      ],
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
    return Column(
      children: [
        Container(
          height: 80.sp,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              _buildCheckTimeColumn(
                  checkIn != null
                      ? DateFormat('hh:mm a').format(checkIn)
                      : 'N/A',
                  'Check In'),
              Container(width: 1, height: 50, color: Colors.black),
              _buildCheckTimeColumn(
                  checkOut != null
                      ? DateFormat('hh:mm a').format(checkOut)
                      : 'N/A',
                  'Check Out'),
              Container(width: 1, height: 50, color: Colors.black),
              _buildCheckTimeColumn(totalHours ?? 'N/A', 'Total Hrs'),
            ],
          ),
        ),
        SizedBox(height: 10.sp),
      ],
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
          style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNoDataAvailableContainer() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Material(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
          elevation: 5,
          child: const SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Icon(
                  Icons.warning,
                  color: Colors.grey,
                  size: 50,
                ),
                SizedBox(height: 5),
                Text(
                  "No Data Available",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
 


    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedIndex == 0)
            Column(
              children: [
                Material(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.tertiary,
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.0.sp, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly filter log',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                            height: 0,
                          ),
                        ),
                        SizedBox(height: 10.sp),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                height: 50.sp,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedMonth,
                                  hint: Text(
                                    "Select Month",
                                    style: TextStyle(
                                        fontSize: 16.sp, color: Colors.black),
                                  ),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: months.map((month) {
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                        DateFormat('MMMM').format(
                                            DateTime(0, int.parse(month))),
                                        style: TextStyle(
                                          fontSize:16.sp,
                                          color: Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMonth = value;
                                    });
                                    widget.callbackMonth(selectedMonth!);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                height: 50.sp,
                                padding:
                                    EdgeInsets.symmetric(horizontal: 10.sp),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedYear,
                                  hint: Text(
                                    "Select Year",
                                    style: TextStyle(
                                        fontSize: 16.sp, color: Colors.black),
                                  ),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.black,
                                  ),
                                  items: years.map((year) {
                                    return DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedYear = value;
                                    });
                                    widget.callbackYear(selectedYear!);
                                  },
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
              ],
            ),
          Container(
            height: 65.sp,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              color: Theme.of(context).colorScheme.tertiary,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(7.5),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(48.0),
                      ),
                      child: Center(
                        child: Text(
                          'Details Stats',
                          style: TextStyle(
                            color: _selectedIndex == 0
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.secondary,
                            fontWeight: _selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16.sp,
                            height: 0.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (selectedMonth == null || selectedYear == null) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                Navigator.of(context).pop(true);
                              }
                            });
                            final Size screenSize = MediaQuery.of(context).size;

                            final double screenWidth = screenSize.width;

                            double baseFontSize15 = 15;
                            double responsiveFontSize15 =
                                baseFontSize15 * (screenWidth / 375);

                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 10.sp,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 25.sp,
                                          backgroundColor:
                                              const Color(0xff3B3A3C),
                                          child: Image.asset(
                                            'assets/warning.png',
                                            width: 50.sp,
                                            height: 50.sp,
                                          ),
                                        ),
                                        SizedBox(height: 10.sp),
                                        Text(
                                          'Invalid Input',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            height: 0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 10.sp),
                                        Text(
                                          'Please select both month & year to proceed',
                                          style: TextStyle(
                                            fontSize: responsiveFontSize15,
                                            color: Colors.grey,
                                            height: 0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(7.5),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(48.0),
                      ),
                      child: Center(
                        child: Text(
                          'Graphical View',
                          style: TextStyle(
                            color: _selectedIndex == 1
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.secondary,
                            fontWeight: _selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16.sp,
                            height: 0.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedIndex == 1 &&
              selectedMonth != null &&
              selectedYear != null)
            GraphicalbuilderMonthly(
              year: int.parse(selectedYear!),
              month: int.parse(selectedMonth!),
            ),
          if (_selectedIndex == 0)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: selectedMonth != null && selectedYear != null
                  ? _getMonthlyAttendanceDetails(
                      widget.uid,
                      int.parse(selectedMonth!),
                      int.parse(selectedYear!),
                    )
                  : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.only(top: 150.0.sp),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20.sp),
                        Text(
                          'No Attendance Month and Year Selected Yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 20.sp,
                            height: 0.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                final attendanceData = snapshot.data!;
                bool allAbsent = attendanceData
                    .every((entry) => entry['status'] == 'Absent');

                if (allAbsent) {
                  return Center(
                    child: _buildNoDataAvailableContainer(),
                  );
                }

                int totalMinutes = 0;

                for (var entry in attendanceData) {
                  final checkIn = entry['checkIn'] as Timestamp?;
                  final checkOut = entry['checkOut'] as Timestamp?;

                  if (checkIn != null && checkOut != null) {
                    final checkInDate = checkIn.toDate();
                    final checkOutDate = checkOut.toDate();
                    totalMinutes +=
                        checkOutDate.difference(checkInDate).inMinutes;
                  }
                }
                const int maxMinutes = 10392;
                const double maxHours = 173.2;
                int remainingMinutes = totalMinutes % 60;

                // ignore: division_optimization
                int totalHours = (totalMinutes / 60).toInt();
                double progressValueInHours =
                    maxHours != 0 ? totalHours / maxHours : 0.0;

                int totalMinutesFromHours = totalHours * 60;
                return Column(children: [
                  const SizedBox(height: 20),
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
                            'Monthly Times Log',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                              height: 0.sp,
                            ),
                          ),
                          SizedBox(height: 20.sp),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 140.sp,
                                width: 170.sp,
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
                                      Text(
                                        'Time in Minutes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16.sp,
                                          height: 0,
                                        ),
                                      ),
                                      Text(
                                        '$totalMinutesFromHours Minutes',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 22.sp,
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
                                        _getMonthDateRange(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
                                          height: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: 140.sp,
                                width: 170.sp,
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
                                      Text(
                                        'Time in Hours',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16.sp,
                                          height: 0,
                                        ),
                                      ),
                                      Text(
                                        '$totalHours.$remainingMinutes Hours',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 22.sp,
                                          height: 0,
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: progressValueInHours,
                                        backgroundColor: Colors.grey[300],
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      Text(
                                        _getMonthDateRange(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.sp,
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
                  SizedBox(height: 20.sp),
                  Material(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Month Date Range: ${_getMonthDateRange()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              height: 0,
                            ),
                          ),
                          SizedBox(height: 10.sp),
                          _buildAttendance(
                              color: const Color(0xff9478F7),
                              data: attendanceData),
                        ],
                      ),
                    ),
                  )
                ]);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}