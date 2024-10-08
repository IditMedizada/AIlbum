import 'package:flutter/material.dart';
import 'dart:math';

class BaseScreen extends StatefulWidget {
  final Widget child;

  const BaseScreen({Key? key, required this.child}) : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFFB3E5FC), const Color(0xFFE1F5FE), _controller.value)!,
                      Color.lerp(const Color(0xFFE1F5FE), const Color(0xFFB3E5FC), _controller.value)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Animated circular shapes
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + 30 * sin(_controller.value * 2 * pi),
                    left: -50 + 30 * cos(_controller.value * 2 * pi),
                    child: CircleAvatar(
                      radius: 150,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    top: 150 + 20 * sin(_controller.value * 2 * pi),
                    right: -100 + 20 * cos(_controller.value * 2 * pi),
                    child: CircleAvatar(
                      radius: 120,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    bottom: -120 + 30 * sin(_controller.value * 2 * pi),
                    left: -80 + 30 * cos(_controller.value * 2 * pi),
                    child: CircleAvatar(
                      radius: 150,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              );
            },
          ),

          // The actual screen content
          widget.child,
        ],
      ),
    );
  }
}