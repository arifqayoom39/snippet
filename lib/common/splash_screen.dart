import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo using PNG image with larger dimensions
                Image.asset(
                  'assets/images/tweet_logo.png',
                  width: 150,
                  height: 150,
                ),
              ],
            ),
          ),
          // Position the presenter text at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: const Center(
              child: Text(
                'Proudly presented by zixno',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
