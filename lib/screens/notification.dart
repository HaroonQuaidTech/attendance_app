import 'package:flutter/material.dart';

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
    double baseFontSize40 = 40;
    double responsiveFontSize40 = baseFontSize40 * (screenWidth / 375);

    double baseFontSize20 = 20;
    double responsiveFontSize20 = baseFontSize20 * (screenWidth / 375);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 65,
    
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
              width: screenSize.width * 0.15,
              height: screenSize.height * 0.06,
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
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Icon(
                      Icons.warning,
                      color: Colors.grey,
                      size: responsiveFontSize40,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "No Notification Available",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 0,
                        fontSize: responsiveFontSize20,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 30),
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
