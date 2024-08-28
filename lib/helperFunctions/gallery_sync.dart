import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class GallerySync extends StatefulWidget {
  @override
  GallerySyncPage createState() => GallerySyncPage();
}

class GallerySyncPage extends State<GallerySync> {
  @override
  void initState() {
    super.initState();
    syncPhotos();
  }
 Future<void> syncPhotos() async {
    String?  user = FirebaseAuth.instance.currentUser?.uid;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    for (final album in albums) {
      final photos = await album.getAssetListRange(start: 0,end: 2);

      for (final photo in photos) {
        final file = await photo.file;
        if (file != null && user != null) {
          await uploadUserPhoto(user, file, photo.createDateTime.toIso8601String());
        }
      }
    }
  }

  Future<void> uploadUserPhoto(String user,File image, String date) async {
    final uri = Uri.parse('http://192.168.1.229:5000/api/photos');
    final request = http.MultipartRequest('POST', uri)
      ..fields['date'] = date
      ..fields['user'] = user
      ..files.add(await http.MultipartFile.fromPath('photo', image.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      print("sucsses");
    }

  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Album Sync'),
      ),
      body: Center(
        child: Text('Syncing Photos...'),
      ),
    );
  }






  // Future<void> syncPhotos() async {
  //   final albums = await PhotoManager.getAssetPathList(
  //     type: RequestType.image,
  //   );

  //   for (final album in albums) {
  //     final photos = await album.getAssetListRange(start: 0,end: 10);

  //     for (final photo in photos) {
  //       final file = await photo.file;
  //       if (file != null) {
  //         await _uploadImage(file, photo);
  //       }
  //     }
  //   }
  // }

  // Future<void> _uploadImage(File image, AssetEntity photo) async {
  //   DateTime? createDateTime = photo.createDateTime;
    
  //   print("this is the path    "   + image.path);
  //   final uri = Uri.parse('http://192.168.1.227:5000/api/photos');
  //   final request = http.MultipartRequest('POST', uri)
  //     ..fields['date'] =createDateTime.toIso8601String()
  //     ..files.add(await http.MultipartFile.fromPath('photo', image.path));

  //   final response = await request.send();

  //   if (response.statusCode == 200) {
  //     print("sucsses");
  //   }
  // }
}

//  Future<void> syncPhotos() async {
//     String?  user = FirebaseAuth.instance.currentUser?.uid;

//     final albums = await PhotoManager.getAssetPathList(
//       type: RequestType.image,
//     );

//     for (final album in albums) {
//       final photos = await album.getAssetListRange(start: 0,end: 10);

//       for (final photo in photos) {
//         final file = await photo.file;
//         if (file != null) {
//           await uploadUserPhoto(user, file, photo.createDateTime.toIso8601String());
//         }
//       }
//     }
//   }


  // Future<void> uploadUserPhoto(String? user,File photo, String date) async {
  //   final storage = FirebaseStorage.instanceFor(bucket: "gs://ailbum.appspot.com");

  //   Reference ref = storage.ref().child('user_photos/$user/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //   UploadTask uploadTask = ref.putFile(photo, SettableMetadata(
  //     customMetadata: {'photoDate': date},
  //   ));

  //   await uploadTask.whenComplete(() => print("Upload complete"));

  // }