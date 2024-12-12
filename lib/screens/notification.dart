import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;

    double baseFontSize20 = 20;
    double responsiveFontSize20 = baseFontSize20 * (screenWidth / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 65.sp,
    
        title: Text(
          "Notification Screen",
          style: TextStyle(fontSize: responsiveFontSize20),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.tertiary,
            child: SizedBox(
              width:12.sp,
              height: 20.sp,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: responsiveFontSize20,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              margin: EdgeInsets.only(bottom: 10.sp),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Center(
                child: Column(
                  children: [
                   SizedBox(height: 30.sp),
                    Icon(
                      Icons.warning,
                      color: Colors.grey,
                      size: 44.sp,
                    ),
                    SizedBox(height: 5.sp),
                    Text(
                      "No Notification Available",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 0.sp,
                        fontSize: 22.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                SizedBox(height: 30.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
