// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;

class Graphicalbuiler extends StatefulWidget {
  const Graphicalbuiler({super.key});

  @override
  State<Graphicalbuiler> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<Graphicalbuiler> {
   Map<String, int> monthlyData = {
    "Present": 0,
    "Absent": 0,
    "On Time": 0,
    "Early Out": 0,
    "Late Arrival": 0,
  };
 Future<Map<String, int>> fetchMonthlyAttendance() async {
  Map<String, int> attendanceData = {
    "Present": 0,
    "Absent": 0,
    "On Time": 0,
    "Late Arrival": 0,
    "Early Out": 0,
  };

  final QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
      .collection('attendance')
      .where('month', isEqualTo: DateTime.now().month) // Fetching current month
      .get();

  for (var doc in attendanceSnapshot.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Check attendance status
    if (data['status'] == 'Present') {
      attendanceData["Present"] = (attendanceData["Present"] ?? 0) + 1;
    } else if (data['status'] == 'Absent') {
      attendanceData["Absent"] = (attendanceData["Absent"] ?? 0) + 1;
    }

    // Check checkIn time for "On Time" and "Late Arrival"
    if (data['checkIn'] != null) {
      DateTime checkIn = (data['checkIn'] as Timestamp).toDate();
      if (checkIn.hour == 8 && checkIn.minute <= 15) {
        attendanceData["On Time"] = (attendanceData["On Time"] ?? 0) + 1;
      } else if (checkIn.hour > 8) {
        attendanceData["Late Arrival"] = (attendanceData["Late Arrival"] ?? 0) + 1;
      }
    }

    // Check checkOut time for "Early Out"
    if (data['checkOut'] != null) {
      DateTime checkOut = (data['checkOut'] as Timestamp).toDate();
      if (checkOut.hour < 17) {
        attendanceData["Early Out"] = (attendanceData["Early Out"] ?? 0) + 1;
      }
    }
  }

  return attendanceData;
}
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
   SizedBox(height: 20,),

     Container(
            height: 482,
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
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  Row(
                    children: [
               Container(
                height: 18,width: 16,
                decoration: BoxDecoration(
                  color:Color(0xff9478F7)
                ),
               ),
               SizedBox(width: 10),

                      Text(
                        'TAT (Turn Around Time)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 45,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}H',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                              },
                              reservedSize: 28,
                              interval:5,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('W1',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 1:
                                    return Text('W2',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 2:
                                    return Text('W3',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 3:
                                    return Text('W4',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 4:
                                    return Text('Fri',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                         
                                  default:
                                    return Text('');
                                }
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                           gridData: FlGridData(show: false), 
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                        barRods: [
    BarChartRodData(
      toY: (monthlyData["Present"] ?? 0).toDouble(), // Null check
      color: Color(0xff9478F7),
      width: 22
    ),
  ],
                          ),
                          BarChartGroupData(
                            x: 1,
                          barRods: [
    BarChartRodData(
      toY: (monthlyData["On Time"] ?? 0).toDouble(), // Null check
      color: Color(0xff22AF41),
      width: 22
    ),
  ],
                          ),
                          BarChartGroupData(
                            x: 2,
                          barRods: [
    BarChartRodData(
      toY: (monthlyData["Late Arrival"] ?? 0).toDouble(), // Null check
      color: Color(0xffF6C15B),
      width: 22
    ),
  ],
                          ),
                          BarChartGroupData(
                            x: 3,
                              barRods: [
    BarChartRodData(
      toY: (monthlyData["Early Out"] ?? 0).toDouble(), // Null check
      color: Color(0xffF07E25),
      width: 22
    ),
  ],
                          ),
                        
                       
                        ],
                      ),
                    ),
                  ),
                    
                ],
              ),
            ),
          ),

        SizedBox(
          height: 30,
        ),
        Container(
          padding: EdgeInsets.all(12),
          height: 430,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Color(0xffEFF1FF),
            // color: Colors.amber,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
                offset: Offset(0, 2), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              PieChart(
                dataMap: monthlyData.map((key, value) => MapEntry(key, value.toDouble())),
                colorList: [
                  Color(0xff9478F7),
                  Color(0xffEC5851),
                  Color(0xff22AF41),
                  Color(0xffF07E25),
                  Color(0xffF6C15B),
                ],
                chartRadius: MediaQuery.of(context).size.width / 1.7,
                legendOptions: LegendOptions(
                  legendPosition: LegendPosition.top,
                  showLegendsInRow: true,
                  showLegends: true,
                  legendShape: BoxShape.circle,
                  legendTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                chartValuesOptions: ChartValuesOptions(
                  showChartValues: false,
                ),
               totalValue: monthlyData.values.reduce((a, b) => a + b).toDouble(),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}