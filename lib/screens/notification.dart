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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50.sp),
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 16.0.sp, vertical: 5.0.sp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                        width: 50.sp,
                        height: 50.sp,
                        child: Material(
                          elevation: 10,
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () {
                       Navigator.pop(context);
                            },
                            child: Material(
                              borderRadius: BorderRadius.circular(12),
                              elevation: 5,
                              color: Theme.of(context).colorScheme.tertiary,
                              child: SizedBox(
                                width: 50.sp,
                                height: 50.sp,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 20.sp,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                Text(
                  'Notification',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    height: 0,
                  ),
                ),
                SizedBox(
                  width: 50.sp,
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ],
      ),
    );
  }
}
