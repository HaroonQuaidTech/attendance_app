// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class Weeklylogtimes extends StatelessWidget {
  const Weeklylogtimes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(0xffEFF1FF),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 4,
                            offset: Offset(0, 2), 
                          ),
                        ],
                      ),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Log Times',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18),
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 118,
                                      width: 168,
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
                                              'Time in mints',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              '2400 Mints',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 20),
                                            ),
                                            LinearProgressIndicator(
                                              value: 0.6,
                                              backgroundColor: Colors.grey[300],
                                              color: Color(0xff9478F7),
                                            ),
                                            Text(
                                              '01 Jan -05 Jan',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 118,
                                      width: 168,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
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
                                              'Time in hours',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            Text(
                                              '40 Hrs',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 20),
                                            ),
                                            LinearProgressIndicator(
                                              value: 0.8,
                                              backgroundColor: Colors.grey[300],
                                              color: Color(0xff9478F7),
                                            ),
                                            Text(
                                              '01 Jan -07 Jan',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ])));

  }
}