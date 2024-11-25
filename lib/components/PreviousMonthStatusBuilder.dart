import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PreviousMonthlyAttendance extends StatefulWidget {
  final String uid;

  const PreviousMonthlyAttendance({super.key, required this.uid});

  @override
  // ignore: library_private_types_in_public_api
  _PreviousMonthlyAttendanceState createState() =>
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

    // Define the first and last day of the month
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Prepare Firestore document fetches for all days in the month
    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> snapshotFutures =
        List.generate(daysInMonth, (i) {
      final date = firstDayOfMonth.add(Duration(days: i));
      final formattedDate = DateFormat('yMMMd').format(date); // Adjusted format

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
      final formattedDate =
          DateFormat('MMM d, yyyy').format(date); 
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
    if (selectedMonth != null && selectedYear != null) {
      int month = int.parse(selectedMonth!);
      int year = int.parse(selectedYear!);

     
      DateTime firstDayOfMonth = DateTime(year, month, 1);
      DateTime lastDayOfMonth =
          DateTime(year, month + 1, 0); 

    
      String startDate = DateFormat('MMM dd').format(firstDayOfMonth);
      String endDate = DateFormat('MMM dd').format(lastDayOfMonth);

      return '$startDate - $endDate';
    }
    return '';
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
              'Weekend',
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

  Color _determineContainerColor(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn != null) {
      final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
      const TimeOfDay earlyOnTime = TimeOfDay(hour: 7, minute: 50);
      const TimeOfDay lateOnTime = TimeOfDay(hour: 8, minute: 10);
      if ((checkInTime.hour == earlyOnTime.hour &&
              checkInTime.minute >= earlyOnTime.minute) ||
          (checkInTime.hour == lateOnTime.hour &&
              checkInTime.minute <= lateOnTime.minute)) {
        return const Color(0xff22AF41);
      } else if (checkInTime.hour > lateOnTime.hour) {
        return const Color(0xffF6C15B); 
      } else {
        return const Color(0xff8E71DF);
      }
    }
    return const Color(0xff8E71DF);
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
                      .format(checkIn) 
                  : 'N/A',
              'Check In'),
          _buildDivider(),
          _buildCheckTimeColumn(
              checkOut != null
                  ? DateFormat('hh:mm a')
                      .format(checkOut) 
                  : 'N/A',
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.tertiary,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly filter log ',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButton<String>(
                              value: selectedMonth,
                              hint: const Text("Select Month"),
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: months.map((month) {
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(DateFormat('MMMM')
                                      .format(DateTime(0, int.parse(month)))),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMonth = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButton<String>(
                              value: selectedYear,
                              hint: const Text("Select Year"),
                              isExpanded: true,
                              underline: const SizedBox(),
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
                  return const Center(child: Text('No attendance data found.'));
                }

                final attendanceData = snapshot.data!;

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
                int totalHours = totalMinutes ~/ 60;
                double progressValueInHours =
                    maxHours != 0 ? totalHours / maxHours : 0.0;

                int totalMinutesFromHours = totalHours * 60;
                return Column(children: [
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
                                fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: screenHeight * 0.18,
                                width: screenWidth * 0.40,
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
                                        'Time in Minutes',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        '$totalMinutesFromHours Minutes',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20),
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
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: screenHeight * 0.18,
                                width: screenWidth * 0.40,
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
                                        value: progressValueInHours,
                                        backgroundColor: Colors.grey[300],
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      Text(
                                        _getMonthDateRange(),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
