import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:my_app/features/user_auth/presentations/pages/createAlbum.dart';

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  AlbumState createState() => AlbumState();
}

class AlbumState extends State<Albums> {
  ValueNotifier<bool> isButtonEnabledNotifier = ValueNotifier(false); // Button state notifier

  @override
  void initState() {
    super.initState();

    // Listen to data sent from the background service
    FlutterBackgroundService().on('sync_complete').listen((data) {
      if (data?["sync_complete"] == true) {
        isButtonEnabledNotifier.value = true; // Enable button
        print("Button enabled after sync completed");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Albums"),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabledNotifier,
            builder: (context, isButtonEnabled, child) {
              return ElevatedButton(
                onPressed: isButtonEnabled
                    ? () {
                        // Navigate to CreateAlbum after the button is enabled
                        print("Navigating to Create Album page");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateAlbum()),
                          (route) => false,
                        );
                      }
                    : null, // Disable button if isButtonEnabled is false
                child: const Text('Create New Album'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
