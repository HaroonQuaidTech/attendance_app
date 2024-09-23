// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:fl_chart/fl_chart.dart' hide PieChart;

class Graphicalbuiler extends StatefulWidget {
  const Graphicalbuiler({super.key});

  @override
  State<Graphicalbuiler> createState() => _GraphicalbuilerState();
}

class _GraphicalbuilerState extends State<Graphicalbuiler> {
    int _currentIndex = 0;
      Widget buildDot({required int index}) {
    return Container(
      width: 12.0,
      height: 4.0,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // shape: BoxShape.rectangle,
        color: _currentIndex == index ? Color(0xff9478F7) : Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
   SizedBox(height: 20,),

      CarouselSlider.builder(
          options: CarouselOptions(
              height: 482,
              viewportFraction: 1.0,
              initialPage: 0,
              enableInfiniteScroll: false,
              reverse: false,
              autoPlay: false,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              }),
          itemCount: 4,
          itemBuilder: (BuildContext context, int index, int realindex) {
          return Container(
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
                        maxY: 8,
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
                              interval: 1,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Mon',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 1:
                                    return Text('Tue',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 2:
                                    return Text('Wed',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600));
                                  case 3:
                                    return Text('Thur',
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
                                  case 5:
                                    return Text('Sat',
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
                                  toY: 8, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                  toY: 7, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                  toY: 6, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                  toY: 5, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                          BarChartGroupData(
                            x: 4,
                            barRods: [
                              BarChartRodData(
                                  toY: 4, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                          BarChartGroupData(
                            x: 5,
                            barRods: [
                              BarChartRodData(
                                  toY: 3, color: Color(0xff9478F7), width: 22),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                       SizedBox(height: 14),
              
                            //----------------------dot indicators--------------------------------
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  4, (index) => buildDot(index: index)),
                            ),
                ],
              ),
            ),
          );
  }),
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
                dataMap: {
                  "Present": 35,
                  "Absent": 5,
                  "On Time": 20,
                  "Early Out": 15,
                  "Late Arrival": 25,
                },
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
                totalValue: 100,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}