// ignore_for_file: use_super_parameters

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
      String uid, int month, int year) async {
    List<Map<String, dynamic>> monthlyAttendanceList = [];
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    final daysInMonth = lastDayOfMonth.day;

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
      final formattedDate = DateFormat('yMMMd').format(date);
      final snapshot = snapshots[i];
      final data = snapshot.data();
      final checkIn = (data?['checkIn'] as Timestamp?)?.toDate();

    if (snapshot.exists && checkIn != null) {
      monthlyAttendanceList.add(data!); // Add attendance data
    } else {
      monthlyAttendanceList.add({
        'date': formattedDate,
        'status': 'Absent', // Mark as Absent if no data found
      });
    }
  }

  return monthlyAttendanceList;
}

  String _getMonthDateRange() {
    if (selectedMonth != null && selectedYear != null) {
      int month = int.parse(selectedMonth!);
      int year = int.parse(selectedYear!);

      // Get the first and last day of the selected month
      DateTime firstDayOfMonth = DateTime(year, month, 1);
      DateTime lastDayOfMonth =
          DateTime(year, month + 1, 0); // last day of the month

      // Format the date range
      String startDate = DateFormat('MMMM dd').format(firstDayOfMonth);
      String endDate = DateFormat('MMMM dd').format(lastDayOfMonth);

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

        // Handle weekend (Saturday/Sunday) and attendance record
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
    // Add your logic to determine the container color
    if (checkIn != null) {
      final TimeOfDay checkInTime = TimeOfDay.fromDateTime(checkIn);
      const TimeOfDay earlyOnTime = TimeOfDay(hour: 7, minute: 50);
      const TimeOfDay lateOnTime = TimeOfDay(hour: 8, minute: 10);
      const TimeOfDay exactCheckIn = TimeOfDay(hour: 8, minute: 0);
      if ((checkInTime.hour == earlyOnTime.hour &&
              checkInTime.minute >= earlyOnTime.minute) ||
          (checkInTime.hour == lateOnTime.hour &&
              checkInTime.minute <= lateOnTime.minute)) {
        return const Color(0xff22AF41); // Green color
      } else if (checkInTime.hour > lateOnTime.hour) {
        return const Color(0xffF6C15B); // Yellow color
      } else {
        return const Color(0xff8E71DF); // Purple color
      }
    }
    return const Color(0xff8E71DF); // Default purple color if no check-in
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
        _buildCheckTimeColumn(checkIn != null
            ? DateFormat('hh:mm a').format(checkIn) // Format Check-In Time
            : 'N/A', 'Check In'),
        _buildDivider(),
        _buildCheckTimeColumn(checkOut != null
            ? DateFormat('hh:mm a').format(checkOut) // Format Check-Out Time
            : 'N/A', 'Check Out'),
        _buildDivider(),
        _buildCheckTimeColumn(totalHours ?? 'N/A', 'Total Hrs'),
      ],
    ),
  );
}

  Widget _buildDateContainer(String formattedDate, String day, Color containerColor) {
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
          formattedDate, // Display the day of the month
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        Text(
          day, // Display the day name
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

  int _calculateMonthlyTotal(List<Map<String, dynamic>?> monthlyData) {
    int totalMinutes = 0;
    for (var data in monthlyData) {
      if (data == null) continue;
      final checkIn = (data['checkIn'] as Timestamp?)?.toDate();
      final checkOut = (data['checkOut'] as Timestamp?)?.toDate();
      if (checkIn != null && checkOut != null) {
        final duration = checkOut.difference(checkIn);
        totalMinutes += duration.inMinutes;
      }
    }
    return totalMinutes;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> _getMonthlyData(
      String userId, DateTime startDate, DateTime endDate) async {
    // Extract month and year from startDate
    final int month = startDate.month;
    final int year = startDate.year;

    // Get the attendance data
    final attendanceData =
        await _getMonthlyAttendanceDetails(userId, month, year);

    // Calculate total hours
    final totalHoursData =
        attendanceData.isNotEmpty ? _calculateMonthlyTotal(attendanceData) : 0;

    return {
      'attendanceData': attendanceData,
      'totalHours': totalHoursData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: selectedMonth,
                hint: const Text("Select Month"),
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
              DropdownButton<String>(
                value: selectedYear,
                hint: const Text("Select Year"),
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
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: selectedMonth != null && selectedYear != null
                ? _getMonthlyAttendanceDetails(
                    widget.uid,
                    int.parse(selectedMonth!), // Parse month
                    int.parse(selectedYear!), // Parse year
                  )
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No attendance data found.'));
              }

              final attendanceData = snapshot.data!;
              return Expanded(
                child: ListView.builder(
                  itemCount: attendanceData.length,
                  itemBuilder: (context, index) {
                    final attendance = attendanceData[index];
                    final date = attendance['date'] ?? 'Unknown Date';
                    final status = attendance['status'] ?? 'Unknown Status';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(date),
                        subtitle: Text('Status: $status'),
                        trailing: Icon(
                          status == 'Absent' ? Icons.close : Icons.check,
                          color: status == 'Absent' ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
