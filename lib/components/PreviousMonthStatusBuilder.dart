import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quaidtech/main.dart';

class PreviousMonthlyAttendance extends StatefulWidget {
  final String uid;
  const PreviousMonthlyAttendance({
    super.key,
    required this.uid,
  });

  @override
  State<PreviousMonthlyAttendance> createState() =>
      _PreviousMonthlyAttendanceState();
}

class _PreviousMonthlyAttendanceState extends State<PreviousMonthlyAttendance> {
  String? selectedMonth;
  String? selectedYear;
  final List<String> months =
      List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  final List<String> years =
      List.generate(10, (index) => (DateTime.now().year - index).toString());

  Future<List<Map<String, dynamic>>> _getMonthlyAttendanceDetails(
      String uid, int month, int year) async {
    List<Map<String, dynamic>> monthlyAttendanceList = [];

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

        final String day = DateFormat('EE').format(date);
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
    final int month = int.parse(selectedMonth!);
    final int year = int.parse(selectedYear!);

    final DateTime firstDayOfMonth = DateTime(year, month, 1);
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const Text(
            'Weekend',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 0,
            ),
          ),
          const SizedBox(width: 30),
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
              checkIn != null ? DateFormat('hh:mm a').format(checkIn) : 'N/A',
              'Check In'),
          _buildDivider(),
          _buildCheckTimeColumn(
              checkOut != null ? DateFormat('hh:mm a').format(checkOut) : 'N/A',
              'Check Out'),
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

  Widget _buildNoDataAvailableContainer() {
    return Material(
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

  @override
Widget build(BuildContext context) {
  final Size screenSize = MediaQuery.of(context).size;
  final double screenHeight = screenSize.height;
  final double screenWidth = screenSize.width;

  // Reusable widget for dropdowns
  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              hint == "Select Month"
                  ? DateFormat('MMMM').format(DateTime(0, int.parse(item)))
                  : item,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Reusable widget for displaying summary cards
  Widget buildSummaryCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              dateRange,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.tertiary,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Filter Log',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: buildDropdown(
                          value: selectedMonth,
                          hint: "Select Month",
                          items: months,
                          onChanged: (value) {
                            setState(() => selectedMonth = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: buildDropdown(
                          value: selectedYear,
                          hint: "Select Year",
                          items: years,
                          onChanged: (value) {
                            setState(() => selectedYear = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                return const Padding(
                  padding: EdgeInsets.only(top: 60.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No Attendance Month Selected.',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final attendanceData = snapshot.data!;
              final allAbsent = attendanceData
                  .every((entry) => entry['status'] == 'Absent');

              if (allAbsent) {
                return Center(child: _buildNoDataAvailableContainer());
              }

             
              // ignore: avoid_types_as_parameter_names
              final totalMinutes = attendanceData.fold<int>(0, (sum, entry) {
                final checkIn = (entry['checkIn'] as Timestamp?)?.toDate();
                final checkOut = (entry['checkOut'] as Timestamp?)?.toDate();
                return sum +
                    (checkIn != null && checkOut != null
                        ? checkOut.difference(checkIn).inMinutes
                        : 0);
              });

              const int maxMinutes = 10392;
              const double maxHours = 173.2;

              final int totalHours = totalMinutes ~/ 60;
              final int remainingMinutes = totalMinutes % 60;
              final double progressValueInHours =
                  maxHours > 0 ? totalHours / maxHours : 0.0;

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
                          const Text(
                            'Monthly Times Log',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildSummaryCard(
                                title: 'Time in Minutes',
                                value: '$totalMinutes Minutes',
                                progress: totalMinutes / maxMinutes,
                                dateRange: _getMonthDateRange(),
                              ),
                              buildSummaryCard(
                                title: 'Time in Hours',
                                value: '$totalHours:$remainingMinutes Hours',
                                progress: progressValueInHours,
                                dateRange: _getMonthDateRange(),
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
                            'Month Date Range: ${_getMonthDateRange()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildAttendance(
                            color: const Color(0xff9478F7),
                            data: attendanceData,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
}