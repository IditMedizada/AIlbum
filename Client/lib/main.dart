// ignore_for_file: avoid_print

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/app/splash_screen/splash_screen.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:my_app/helperFunctions/gallery_sync.dart';

ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier(true); // Button state notifier

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCRoY8tAawlcPC9GAZls4kturQQm23CVD0",
      appId: "1:808160337385:web:72decfeac9489d7bd97f78",
      messagingSenderId: "808160337385",
      projectId: "ailbum",
    ),
  );

  // Initialize background service
  await initializeService();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-lbum',
      home: SplashScreen(
        child: LoginPage(),
      ),
    );
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Check if the service is already running
  bool isRunning = await service.isRunning();
  print("sssssssssssssssssssssssssssssssssssssssssssssssssssss $isRunning");
  if (!isRunning) {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'my_foreground_channel',
        initialNotificationTitle: 'Service Running',
        initialNotificationContent: 'Service is running in the background.',
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        autoStart: true,
      ),
    );

    try {
      await service.startService();
    } catch (e) {
      print("Error starting service: $e");
    }  }
}

// Foreground service callback
void onStart(ServiceInstance service) async {
  // Initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Ensure that the service runs as a foreground service immediately
  if (service is AndroidServiceInstance) {
    // Start the service as a foreground service as soon as possible
    service.setAsForegroundService();

    // Show the notification right after starting the foreground service
    service.setForegroundNotificationInfo(
      title: "AI-lbum Service",
      content: "Background service is running",
    );
  }

  // Handle photo uploads in the background
  service.on('upload_photos').listen((event) async {
    final userId = event!["userId"];
    await GallerySync().syncPhotos(userId);
    service.invoke('sync_complete', {"sync_complete": true});
  });

  // Handle night mode uploads periodically
  service.on('night_mode').listen((event) async {
    final userId = event!["userId"];
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      await GallerySync().nightModePhotoUploading(userId);
    });
  });

  // Stop the service when requested
  service.on("stopService").listen((event) async {
    await service.stopSelf();
  });
}
