// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';
import 'package:my_app/features/user_auth/presentations/pages/userId.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({super.key, this.child});

  @override
  State<StatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () async {
      String? userId = await getUserId();
      if (userId != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Albums()), 
          (route) => false,
        );
      }else{
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => widget.child!),
            (route) => false,
          );
      }
      
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgroud.jpg'), // Change to your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Icon in the center
          const Center(
          child: Image(
            image: AssetImage('assets/icon.png'),
            width: 200.0,  // Adjust the size as needed
            height: 200.0,
          ),
          ),
        ],
      ),
    );
  }
}
