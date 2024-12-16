import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class MonthlyAttendance extends StatefulWidget {
  final Color color;
  final String? dropdownValue2;
  const MonthlyAttendance({
    super.key,
    required this.color,
    required this.dropdownValue2,
    required String uid,
  });

  @override
  State<MonthlyAttendance> createState() => _MonthlyAttendanceState();
}

class _MonthlyAttendanceState extends State<MonthlyAttendance> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isLoading = true;
  List<Map<String, dynamic>> monthlyData = [];
  List<Map<String, dynamic>> lateArrivals = [];
  List<Map<String, dynamic>> absents = [];
  List<Map<String, dynamic>> onTime = [];
  List<Map<String, dynamic>> earlyOuts = [];
  List<Map<String, dynamic>> presents = [];

  Future<void> _getMonthlyAttendance(String uid) async {
    DateTime today = DateTime.now();
    int lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;

    for (int day = 1; day <= lastDayOfMonth; day++) {
      DateTime currentDate = DateTime(today.year, today.month, day);
      String formattedDate = DateFormat('yMMMd').format(currentDate);
      String formattedDay = DateFormat('EEE').format(currentDate);
      if (currentDate.weekday == DateTime.saturday ||
          currentDate.weekday == DateTime.sunday) {
        continue;
      }
      if (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('AttendanceDetails')
                .doc(uid)
                .collection('dailyattendance')
                .doc(formattedDate)
                .get();

        if (snapshot.exists) {
          Map<String, dynamic>? data = snapshot.data();

          if (data != null) {
            DateTime? checkInTime = (data['checkIn'] as Timestamp?)?.toDate();
            DateTime? checkOutTime = (data['checkOut'] as Timestamp?)?.toDate();

            List<String> statuses = [];

            if (checkInTime == null) {
              statuses.add("Absent");
            } else {
              statuses.add("Present");

              if (checkInTime.isAfter(DateTime(currentDate.year,
                  currentDate.month, currentDate.day, 8, 15))) {
                statuses.add("Late Arrival");
              }

              if (checkOutTime != null &&
                  checkOutTime.isBefore(DateTime(currentDate.year,
                      currentDate.month, currentDate.day, 17, 0))) {
                statuses.add("Early Out");
              }

              if (checkInTime.isAfter(DateTime(currentDate.year,
                      currentDate.month, currentDate.day, 7, 50)) &&
                  checkInTime.isBefore(DateTime(currentDate.year,
                      currentDate.month, currentDate.day, 8, 16))) {
                statuses.add("On Time");
              }
            }

            data['formattedDate'] = formattedDate;
            data['formattedDay'] = formattedDay;
            data['statuses'] = statuses;

            monthlyData.add(data);
          }
        } else {
          monthlyData.add({
            "checkIn": null,
            "checkOut": null,
            "statuses": ["Absent"],
            "formattedDate": formattedDate,
            "formattedDay": formattedDay,
          });
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  String _calculateTotalHours(Timestamp? checkIn, Timestamp? checkOut) {
    if (checkIn == null || checkOut == null) return '0:00';
    DateTime checkInTime = checkIn.toDate();
    DateTime checkOutTime = checkOut.toDate();
    Duration duration = checkOutTime.difference(checkInTime);
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "--:--";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _getMonthlyAttendance(userId);
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtereedData = widget.dropdownValue2 == 'Select'
        ? monthlyData
        : widget.dropdownValue2 == 'On Time'
            ? monthlyData
                .where((element) =>
                    (element['statuses'] as List).contains('On Time'))
                .toList()
            : widget.dropdownValue2 == 'Absent'
                ? monthlyData
                    .where((element) =>
                        (element['statuses'] as List).contains('Absent'))
                    .toList()
                : widget.dropdownValue2 == 'Early Out'
                    ? monthlyData
                        .where((element) =>
                            (element['statuses'] as List).contains('Early Out'))
                        .toList()
                    : widget.dropdownValue2 == 'Late Arrival'
                        ? monthlyData
                            .where((element) => (element['statuses'] as List)
                                .contains('Late Arrival'))
                            .toList()
                        : monthlyData;
    return Column(
      children: [
        if (isLoading)
          Column(
            children: [
              SizedBox(
                height: 30.sp,
              ),
              const Center(
                child: CircularProgressIndicator(),
              ),
              SizedBox(
                height: 30.sp,
              ),
            ],
          )
        else if (filtereedData.isEmpty)
          Center(
            child: Column(
              children: [
                SizedBox(height: 30.sp),
                Icon(
                  Icons.warning,
                  color: Colors.grey,
                  size: 50.sp,
                ),
                const SizedBox(height: 5),
                Text(
                  "No Data Available",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 0.sp,
                    fontSize: 20.sp,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          )
        else
          ListView.builder(
              primary: false,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                if (index >= 0 && index < filtereedData.length) {
                  Map<String, dynamic> data = filtereedData[index];
                  final DateTime date = DateFormat('MMM dd, yyyy')
                      .parse(filtereedData[index]['formattedDate']);
                  final String day = DateFormat('EE').format(date);
                  final String formattedDate = DateFormat('dd').format(date);

                  String checkInTime =
                      _formatTime(data['checkIn'] as Timestamp?);
                  String checkOutTime =
                      _formatTime(data['checkOut'] as Timestamp?);
                  String totalHours = _calculateTotalHours(
                    data['checkIn'] as Timestamp?,
                    data['checkOut'] as Timestamp?,
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 80.sp,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60.sp,
                              height: 60.sp,
                              decoration: BoxDecoration(
                                color: widget.color,
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
                                    ),
                                  ),
                                  SizedBox(height: 5.sp),
                                  Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              checkInTime,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Check In',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          decoration: const BoxDecoration(color: Colors.black),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              checkOutTime,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Check Out',
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          decoration: const BoxDecoration(color: Colors.black),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalHours,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Total Hours',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return null;
              }),
      ],
    );
  }
}
