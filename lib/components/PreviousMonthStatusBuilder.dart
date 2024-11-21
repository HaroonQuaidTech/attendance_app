// ignore_for_file: use_super_parameters

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
}
