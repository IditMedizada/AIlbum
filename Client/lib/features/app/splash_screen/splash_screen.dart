// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:my_app/features/client_side/presentations/pages/albums.dart';
import 'package:my_app/features/client_side/presentations/pages/userId.dart';
import 'package:my_app/features/client_side/presentations/widgets/BaseScreen.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({super.key, this.child});

  @override
  State<StatefulWidget> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
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
            // removing all previous screens from the navigation stack
            (route) => false,
          );
      }
      
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
    
    child:
          // Icon in the center
          Center(
          child: Image(
            image: AssetImage('assets/icon.png'),
            width: 200.0,  // Adjust the size as needed
            height: 200.0,
          ),
          ),
    );
  }
}
