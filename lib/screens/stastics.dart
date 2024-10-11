// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:quaidtech/components/graphicalbuildermonthly.dart';
import 'package:quaidtech/components/graphicalweekly.dart';
import 'package:quaidtech/components/statusbuilderweekly.dart';
import 'package:quaidtech/components/statusbuildermonthly.dart';
import 'package:quaidtech/components/weeklyattenance.dart';
import 'package:quaidtech/screens/home.dart';
import 'package:quaidtech/screens/notification.dart';

class StatsticsScreen extends StatefulWidget {
  const StatsticsScreen({
    super.key,
  });

  @override
  State<StatsticsScreen> createState() => _StatsticsScreenState();
}

class _StatsticsScreenState extends State<StatsticsScreen> {
  String dropdownValue1 = 'Weekly';
  String dropdownValue2 = 'Select';
  String dropdownValue3 = 'Select Month';
  String dropdownValue4 = 'Select Year';

  int _selectedIndex = 0;

//----------------------------------------------------------------------------

  Widget _buildWeeklyAttendance(
      String text, Color color, String dropdownValue2) {
    return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xffEFF1FF),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(
            height: 10,
          ),
          //----------------------------------------
          WeeklyAttendance(
            color: color,
            dropdownValue2: dropdownValue2,
          ),
        ]));
  }

  Widget _buildMonthlyAttendance(
      String text, Color color, String dropdownValue2) {
    return Container(
        padding: EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Color(0xffEFF1FF),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          SizedBox(
            height: 10,
          ),
          //----------------------------------------
          WeeklyAttendance(
            color: color,
            dropdownValue2: dropdownValue2,
          ),
        ]));
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
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(48.0),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 18),
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
        detailsColor = Color(0xffF6C15B);
        break;
      case 'Absent':
        detailsType = 'Absent Details';
        detailsColor = Color(0xffEC5851);
        break;
      case 'On Time':
        detailsType = 'On Time Details';
        detailsColor = Color(0xff22AF41);
        break;
      case 'Early Out':
        detailsType = 'Early Out Details';
        detailsColor = Color(0xffF07E25);
        break;
      case 'Present':
        detailsType = 'Present Details';
        detailsColor = Color(0xff8E71DF);
        break;
      default:
        return SizedBox.shrink(); 
    }

   
    return isWeekly
        ? _buildWeeklyAttendance(detailsType, detailsColor, dropdownValue2)
        : _buildMonthlyAttendance(detailsType, detailsColor, dropdownValue2);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.transparent,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                          );
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    const Text(
                      'Statistics',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen()),
                          );
                        },
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              //-----------------------------Filter container-------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_selectedIndex != 1)
                        Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xffEFF1FF),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(
                                    0, 2), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filter',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // First Dropdown
                                      Expanded(
                                        child: Container(
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
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
                                                fontSize: 16),
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
                                      const SizedBox(width: 16),
                                      // Second Dropdown
                                      Expanded(
                                        child: Container(
                                          height: 50,
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
                                                fontSize: 16),
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
                                ]),
                          ),
                        ),

                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          children: [
                            // Check for Weekly or Monthly Attendance
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

                      //------------------------------------ygrt----------------------------------------------------
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
                            color: const Color(0xffEFF1FF),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(
                                    0, 2), // changes position of shadow
                              ),
                            ],
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
                          const StatusBuiler(),

                      if (dropdownValue1 == 'Weekly' && _selectedIndex == 1)
                        GraphicalbuilerWeekly(),
                      if (dropdownValue1 == 'Monthly' && _selectedIndex == 1)
                        GraphicalbuilerMonthly()
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
