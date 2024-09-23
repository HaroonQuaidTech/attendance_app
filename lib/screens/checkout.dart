// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
return Scaffold(
  
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0,right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // light background color
                          borderRadius:
                              BorderRadius.circular(12), // rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Check Out',
                        style: TextStyle(fontSize: 22,fontWeight: FontWeight.w600),
                      ),
                             Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // light background color
                          borderRadius:
                              BorderRadius.circular(12), // rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                         Icons.notifications_none,
                          color: Colors.black,
                        ),
                      ),
                      // Image.asset(
                      //   'assets/icon.png',
                      //   height: 72,
                      //   width: 72,
                      // )
                    ],
                  ),
                ),
              ),
              Text(
                '05:00 PM',
                style: TextStyle(fontSize: 40, color: Color(0xffFB3F4A)),
              ),
              Text(
                'Feb19,2024-Monday',
                style: TextStyle(fontSize: 20, color: Color(0xffFB3F4A)),
              ),
              SizedBox(
                height: 50,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Circle
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                       color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xffFB3F4A), width: 2),
                    ),
                  ),
                  // Middle Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                       color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xffFB3F4A), width: 2),
                    ),
                  ),
                  // Inner Circle with Icon and Text
                  Container(
                    width: 115,
                    height: 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/mingout.png',
                          height: 42,
                          width: 42,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Check Out",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
              SizedBox(
                height: 140,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 116,
                        width: 115,
                        decoration: BoxDecoration(
                            color: Color(0xffEFF1FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset(
                              'assets/checkin.png',
                              height: 42,
                              width: 42,
                            ),
                            Text(
                              '08:00 AM',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                            ),
                            Text(
                              'Check In',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 116,
                        width: 115,
                        decoration: BoxDecoration(
                            color: Color(0xffEFF1FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset(
                              'assets/checkin.png',
                              height: 42,
                              width: 42,
                            ),
                            Text(
                              '05:00 PM',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                            ),
                            Text(
                              'Check Out',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 116,
                        width: 115,
                        decoration: BoxDecoration(
                            color: Color(0xffEFF1FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Image.asset(
                              'assets/checkin.png',
                              height: 42,
                              width: 42,
                            ),
                            Text(
                              '09:00',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w400),
                            ),
                            Text(
                              'Total Hrs',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
