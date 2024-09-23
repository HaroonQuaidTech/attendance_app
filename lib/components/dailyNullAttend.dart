// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, file_names, depend_on_referenced_packages, unnecessary_string_interpolations, unused_local_variable, unused_element



import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyEmptyAttendance extends StatefulWidget {

  final DateTime? selectedDay;
  const DailyEmptyAttendance({Key? key,required this.selectedDay}) : super(key: key);

  @override
  State<DailyEmptyAttendance> createState() => _DailyAttendanceState();
}

class _DailyAttendanceState extends State<DailyEmptyAttendance> {

  final String userId = FirebaseAuth.instance.currentUser!.uid;



  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    DateTime now = DateTime.now();

    // Access the data passed to this screen
  
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: screenHeight * 0.1,
      width: screenWidth * 0.90,
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
                    color: Color(0xffEC5851),
                    borderRadius: BorderRadius.circular(6)),
                child: Column(
                  children: [
                    Text(
                      widget.selectedDay != null
          ? DateFormat('dd').format(widget.selectedDay!)  
          : '--', 
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      widget.selectedDay != null
          ? DateFormat('EE').format(widget.selectedDay!)  
          : '--', 
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 50,),
          Center(
            child: Text(
             'No Data Availabe',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          ),
        
       
      
        ],
      ),
    );
  }
}
