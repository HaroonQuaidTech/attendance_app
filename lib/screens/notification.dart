import 'package:flutter/material.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              SizedBox(
                height: 70,
                width: double.infinity,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Text(
                        'Notification',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
              ),
              Container(
                height: 250,
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: const Color(0xffEFF1FF),
                    borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit dolor ',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                '1m ago.',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6C6C6C)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                    Container(
                        width: 330,
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                'Lorem ipsum dolor sit amet,\nconsectetur adipiscing elit dolor ',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                '1d ago.',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6C6C6C)),
                              ),
                            ],
                          ),
                        )),
                   
                  
                  
                  
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
