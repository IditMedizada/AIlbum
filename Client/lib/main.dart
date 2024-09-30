
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/app/splash_screen/splash_screen.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:my_app/helperFunctions/gallery_sync.dart';

ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier(true); // Button state notifier
final service = FlutterBackgroundService();

// Map<String, ValueNotifier<bool>> buttonStateNotifiers = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCRoY8tAawlcPC9GAZls4kturQQm23CVD0",
      appId: "1:808160337385:web:72decfeac9489d7bd97f78",
      messagingSenderId: "808160337385",
      projectId: "ailbum",
    ),
  );


  await initializeService();
  runApp(const MyApp());

  service.startService();
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-lbum',
      home: SplashScreen(
        child:  LoginPage(),
        ),
    );
  }
}

Future<void> initializeService() async {

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true, // Ensures the service starts in the foreground
      notificationChannelId: 'my_foreground_channel',
      initialNotificationTitle: 'Uploading Photos',
      initialNotificationContent: 'Uploading photos in progress...',
      foregroundServiceNotificationId: 888, // Unique notification ID
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: true,
    ),
  );


}


void onStart(ServiceInstance service) async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Check if the service is running as a foreground service
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService(); // This is the correct method for foreground services

    service.setForegroundNotificationInfo(
      title: "Uploading Photos",
      content: "Uploading photos in the background.",
    );
  }

  // Listen for events
  service.on('upload_photos').listen((event) async {
      final userId = event!["userId"];
      await GallerySync().syncPhotos(userId);
      service.invoke('sync_complete', {"sync_complete": true});
      service.stopSelf();

  });

 // Listening for stopService action
  service.on("stopService").listen((event) {
    service.stopSelf();

  });

  // Start a periodic task every 24 hours
  Timer.periodic(const Duration(minutes:20), (timer) async {
      await GallerySync().nightModePhotoUploading();
  });
}

 

