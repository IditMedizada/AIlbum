import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/features/user_auth/presentations/pages/albums.dart';
import 'package:my_app/features/user_auth/presentations/pages/photoDisplayPage.dart';
import 'package:http/http.dart' as http;

class AlbumItem extends StatelessWidget {
  final String albumName;
  final String thumbnailUrl;
  final String albumId;
  final Function() onAlbumDeleted; // Callback for album deletion

  const AlbumItem({
    Key? key,
    required this.albumId,
    required this.albumName,
    required this.thumbnailUrl,
    required this.onAlbumDeleted, // Update the constructor

  }) : super(key: key);

Future<void> onDelete(BuildContext context,String albumPath) async {
  print('enter hereeeeeeeeeeeee');
  final uri = Uri.parse('http://192.168.1.8:5000/api/photos/delete-album');
  print(albumPath);
  // Send the request as JSON
  var response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'albumPath': albumPath
    }),
  );

  if (response.statusCode == 200) {
     onAlbumDeleted(); // Call the callback to refresh albums

  }
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle the album click
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        String albumIdd = '$userId/user_albums/$albumId';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDisplayPage(albumId: albumIdd, albumName: albumName),
          ),
        );
      },
      onLongPress: () {
        // Show a dialog to confirm deletion
        showDeleteConfirmationDialog(context);
      },
      child: Card(
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Album Thumbnail with larger size
            Expanded(
              child: AspectRatio(
                aspectRatio: 4 / 3, // Adjusted aspect ratio for more height
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover, // Cover the area without distortion
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.photo_album,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Album Name
            Padding(
              padding: const EdgeInsets.all(8.0), // Adjust padding if needed
              child: Text(
                albumName,
                textAlign: TextAlign.center,
                maxLines: 1, // Limit to one line
                overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Smaller font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Album'),
          content: const Text('Are you sure you want to delete this album?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
              String? userId = FirebaseAuth.instance.currentUser?.uid;
              String albumIdd = '$userId/user_albums/$albumId';
              await onDelete(context,albumIdd); // Call the delete callback
              Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
