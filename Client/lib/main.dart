import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/app/splash_screen/splash_screen.dart';
import 'package:my_app/features/user_auth/presentations/pages/login_page.dart';
import 'package:my_app/features/user_auth/presentations/pages/sign_up_page.dart';
import 'package:my_app/helperFunctions/gallery_sync.dart';


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

  // await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // await Workmanager().registerPeriodicTask(
  //   "uniqueNightlyPhotoUploadTask",  // Use a unique task name
  //   "nightlyPhotoUploadTask",
  //   frequency: const Duration(minutes: 15), // Adjust frequency as needed
  //   inputData: <String, dynamic>{
  //     'user': FirebaseAuth.instance.currentUser?.uid,
  //   },
  // );
  // await initializeService();

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
        child:  LoginPage(),
        ),
    );
  }
}

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'AWESOME SERVICE',
//       initialNotificationContent: 'Initializing',
//       foregroundServiceNotificationId: 888,
//       foregroundServiceTypes: [AndroidForegroundType.location],
//     ),
//     iosConfiguration: IosConfiguration(
//       onForeground: onStart,
//       autoStart: true,
//     ),
//   );

//   // Ensure the service starts
//   service.startService();
// }

// void onStart(ServiceInstance service) {
//   DartPluginRegistrant.ensureInitialized();

//   if (service is AndroidServiceInstance) {
//     service.on('startUpload').listen((event) {
//       // Process the event and sync photos
//       GallerySyncPage().syncPhotos();
//     });
//   }
// }

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print("Callback Dispatcher invoked with task: $task and inputData: $inputData");

//     if (task == "nightlyPhotoUploadTask" && inputData != null) {
//       String? userId = inputData['user'];
//       if (userId != null) {
//         // Ensure this operation does not require any UI context
//         await GallerySyncPage().uploadNewPhotos(userId);
//         print("Photos uploaded for user: $userId");
//       }
//     }
//     return Future.value(true);
//   });
// }
