// ignore_for_file: avoid_print

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoDisplayPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const PhotoDisplayPage({super.key, required this.albumId, required this.albumName});

  @override
  PhotoDisplayPageState createState() => PhotoDisplayPageState();
}

class PhotoDisplayPageState extends State<PhotoDisplayPage> {
  List<String> photoUrls = [];
  int isDownloading = 0;
  final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  // Future<void> downloadAndSavePhotos() async {
  //   setState(() {
  //     isDownloading = 1;
  //   });

  //   // Request permission to access storage
  //   // if (await requestPermission()) {
  //     // Specify a custom album name
  //     String albumName = widget.albumName;
  //     // Create a folder for the album in the gallery
  //     Directory albumDir = await createAlbumDirectory(albumName);

  //     // Download all photos in parallel and save them to the folder
  //     String folderPath = '/storage/emulated/0/Pictures/Gallery/owner/$albumName';
  //     await downloadPhotosInParallel(folderPath);

  // // Wait for all downloads to complete
  // // await Future.wait(downloadTasks);      print('All photos downloaded and saved to $albumName!');
  //     setState(() {
  //       isDownloading = 2;
  //     });
  //   // }else{print("not goodddddddddddddddddddddddddddddddddddddddddddd");}
  // }

  // Future<void> downloadPhotosInParallel(String folderPath) async {
  //   List<Future<void>> downloadTasks = [];

  //   for (String url in photoUrls) {
  //     downloadTasks.add(downloadPhoto(url, folderPath));
  //   }

  //   // Wait for all downloads to complete
  //   await Future.wait(downloadTasks);
  // }
  // Future<void> downloadAndSavePhoto(String photoUrl, String folderPath) async {
  //   try {
  //     // Download the photo data from Firebase Storage
  //     print(photoUrl);
  //     Uint8List? imageData = await downloadPhoto(photoUrl);
  //     if (imageData != null) {
  //       // Save the photo to the specified folder in the gallery
  //       await ImageGallerySaver.saveImage(
  //         imageData,
  //         quality: 100,
  //         name: DateTime.now().toIso8601String(), // Use timestamp to ensure unique name
  //         isReturnImagePathOfIOS: true,
  //       );
  //       print('Photo saved successfully!');
  //     }
  //   } catch (e) {
  //     print('Error saving photo: $e');
  //   }
  // }

// Future<void> downloadPhoto(String photoUrl, String folderPath) async {
//   try {
//     final response = await http.get(Uri.parse(photoUrl));

//     if (response.statusCode == 200) {
//       final fileName = photoUrl.split('/').last;

//       // Create a directory if it doesn't exist
//       print(folderPath);
//       Directory directory = Directory(folderPath);
//       if (!(await directory.exists())) {
//         await directory.create(recursive: true);
//       }

//       final filePath = '${directory.path}/$fileName';
//       final file = File(filePath);
//       await file.writeAsBytes(response.bodyBytes);

//       print('Downloaded: $filePath');
//     } else {
//       print('Failed to download photo: ${response.statusCode}');
//     }
//   } catch (e) {
//     print('Error downloading photo: $e');
//   }
// }


  // Future<Directory> createAlbumDirectory(String albumName) async {
  //   Directory directory;
  //   if (Platform.isAndroid) {
  //     directory = Directory('/storage/emulated/0/Pictures/Gallery/owner/$albumName');
  //   } else {
  //     directory = await getApplicationDocumentsDirectory(); // iOS: can save in app directory
  //   }
  //   if (!(await directory.exists())) {
  //     await directory.create(recursive: true);
  //   }
  //   return directory;
  // }

//   Future<bool> requestPermission() async {
//     var status = await Permission.storage.status;
//     if (!status.isGranted) {
//       status = await Permission.storage.request();
//     }
//     return status.isGranted;
//   }

  

  Future <void> loadPhotos() async {
    try {
       
        Reference storageRef = storage.ref().child(widget.albumId);
        final ListResult result = await storageRef.listAll(); // Get all files in the path
        // Iterate over each item and get the download URL
        for (var ref in result.items) {
          final String url = await ref.getDownloadURL();
          setState(() {
            photoUrls.add(url);
          });
        }
    } catch (e) {
      print("Failed to load photos: $e");
    }
  }

Future<void> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}


Future<void> downloadPhotosToPhone(String albumName) async {
  try {
     setState(() {
        isDownloading = 1;
      });
    // Ensure permission to write to storage is granted
    await requestStoragePermission();

    // Specify the directory on the phone where photos will be saved
    Directory directory = Directory('/storage/emulated/0/Pictures/Gallery/owner/$albumName');
    
    // If the directory doesn't exist, create it
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    
    // Get the reference to your album in Firebase Storage
    
    Reference storageRef = storage.ref().child(widget.albumId);
    final ListResult result = await storageRef.listAll(); // Get all files in the path
    // Iterate over each photo in the album
    for (Reference ref in result.items) {
      // Get the file name from the reference
      String fileName = ref.name;
      // Download the photo data
      final data = await ref.getData();
      // Save the photo to the specified directory on the phone
      File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(data!);
       setState(() {
        isDownloading = 2;
        });
    }
    refreshGallery(widget.albumId);
    print("Photos downloaded successfully to: ${directory.path}");
  } catch (e) {
    print("Error downloading photos: $e");
  }
}
  
  

void refreshGallery(String albumName) async {
  final String path = '/storage/emulated/0/Pictures/Gallery/owner/$albumName';
  await const MethodChannel('com.example.app/media').invokeMethod('refreshGallery', path);
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (context) => const Albums()), (route) => false);
        },
      ),
      title: Text(widget.albumName),
    ),
    body: photoUrls.isEmpty
        ? const Center(child: Text('No photos available.'))
        : Column(
            children: [
              // Display all photos in a GridView when photoUrls is not empty
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: photoUrls.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      photoUrls[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Download button and progress indicator based on isDownloading state
              if (isDownloading == 0) // State: Ready to Download
                ElevatedButton(
                  onPressed: () => downloadPhotosToPhone(widget.albumName),
                  child: const Text('Download Photos'),
                ),
              if (isDownloading == 1) // State: Downloading
                const Center(child: CircularProgressIndicator()), // Show progress
              if (isDownloading == 2) // State: Download Completed
                ElevatedButton(
                  onPressed: () {
                     
                  },
                  child: const Text('Download Completed'),
                ),
            ],
          ),
  );
}
}
